"""
Regenerate fresh RS256 JWTs for Kasm Workspaces components stuck in restart-loop
because their auth_token has expired beyond the api_token_refresh_leeway window.

USAGE (must run inside the kasm_api container):
    docker cp regen_component_jwts.py kasm_api:/tmp/
    docker exec kasm_api python3 /tmp/regen_component_jwts.py

Affects: kasm_guac, kasm_rdp_gateway, kasm_rdp_https_gateway
- Reads api_private_key from settings (decrypted in-memory by DataAccessPostgres)
- Preserves each component's original connection_proxy_id (taken from existing YAML)
- Re-inserts the proxy row in DB if it was deleted (e.g. via UI cleanup)
- Updates the auth_token in the YAML, saves a .bak

After running, restart the components:
    docker restart kasm_guac kasm_rdp_gateway kasm_rdp_https_gateway

Validate with:
    docker logs --since 1m kasm_api 2>&1 | grep -iE 'expired|unauthorized|403'
    docker exec kasm_db psql -U kasmapp -d kasm -c \\
      "SELECT connection_proxy_type, operational_status, last_reported FROM connection_proxies;"
"""

import sys, base64, json, datetime, shutil

# These paths match the kasm_api container's filesystem layout (Kasm 1.18.x)
sys.path.insert(0, '/src')
sys.path.insert(0, '/src/api_server')

import yaml
from data.access_postgres import DataAccessPostgres
import utils

JA = utils.JWT_AUTHORIZATION

# Load API config and create DB handle
with open('/opt/kasm/current/conf/app/api/api.app.config.yaml') as f:
    cfg = yaml.safe_load(f)
db = DataAccessPostgres(config=cfg)

private_key = db.get_config_setting_value('auth', 'api_private_key')
exp_seconds = int(db.get_config_setting_value('auth', 'api_token_lifespan_seconds'))
assert private_key.startswith('-----BEGIN'), 'private_key did not decrypt correctly'

# Pull any existing zone_id; fall back to a UUID if there are zero proxies left
existing = db.get_connection_proxies()
default_zone = (
    existing[0].zone_id if existing
    else '943e50ac-9e26-4505-9633-d9ec8f346974'  # adapt if your default differs
)
print(f'zone={default_zone}  exp_secs={exp_seconds}')

COMPS = [
    {
        'name': 'guac',
        'yaml': '/opt/kasm/current/conf/app/guac/kasmguac.app.config.yaml',
        'token_path': ['api', 'auth_token'],
        'exp_path':   ['api', 'auth_token_exp'],
        'proxy_type': 'GUAC',
        'authorizations': [JA.GUAC],          # value 80
        'proxy_port': None,
        'server_port': 443,
    },
    {
        'name': 'rdp_gateway',
        'yaml': '/opt/kasm/current/conf/app/rdp_gateway/passthrough.app.config.yaml',
        'token_path': ['api', 'auth_token'],
        'exp_path':   ['api', 'auth_token_exp'],
        'proxy_type': 'RDP-GATEWAY',
        'authorizations': [JA.RDP_GATEWAY],   # value 90
        'proxy_port': 3389,
        'server_port': 443,
    },
    {
        'name': 'rdp_https_gateway',
        'yaml': '/opt/kasm/current/conf/app/rdp_https_gateway/rdp_https_gateway.app.config.yaml',
        'token_path': ['api', 'auth_token'],
        'exp_path':   ['api', 'auth_token_expiration'],  # different key on this YAML
        'proxy_type': 'RDP-HTTPS-GATEWAY',
        'authorizations': [JA.RDP_GATEWAY],   # same enum, different proxy_type
        'proxy_port': None,
        'server_port': 443,
    },
]


def b64d(s: str) -> bytes:
    s += '=' * (-len(s) % 4)
    return base64.urlsafe_b64decode(s)


def decode_payload(jwt: str) -> dict:
    return json.loads(b64d(jwt.split('.')[1]))


for c in COMPS:
    print(f"\n=== {c['name']} ===")
    with open(c['yaml']) as f:
        y = yaml.safe_load(f)

    cur_token = y[c['token_path'][0]][c['token_path'][1]]
    pid = decode_payload(cur_token)['connection_proxy_id']
    print(f'  current proxy_id: {pid}')

    new_token = utils.generate_jwt_token(
        data={'connection_proxy_id': pid},
        authorizations=c['authorizations'],
        private_key=private_key,
        expires_seconds=exp_seconds,
    )
    new_payload = decode_payload(new_token)
    exp_ts = new_payload['exp']
    print(f'  new exp: {exp_ts} ({datetime.datetime.utcfromtimestamp(exp_ts)} UTC)')

    ep = db.get_connection_proxy(connection_proxy_id=pid)
    if ep:
        print('  DB row exists -> updating auth_token')
        db.update_connection_proxy(ep, auth_token=new_token)
    else:
        print('  DB row missing -> creating')
        db.create_connection_proxy(
            server_address='proxy',
            server_port=c['server_port'],
            connection_proxy_type=c['proxy_type'],
            auth_token=new_token,
            zone_id=default_zone,
            proxy_port=c['proxy_port'],
            connection_proxy_id=pid,
        )

    shutil.copy2(c['yaml'], c['yaml'] + '.bak')
    y[c['token_path'][0]][c['token_path'][1]] = new_token
    if c['exp_path']:
        y[c['exp_path'][0]][c['exp_path'][1]] = exp_ts
    with open(c['yaml'], 'w') as f:
        yaml.safe_dump(y, f, default_flow_style=False)
    print(f'  YAML updated (.bak saved at {c["yaml"]}.bak)')

print('\nDONE. Now run on the host:')
print('  docker restart kasm_guac kasm_rdp_gateway kasm_rdp_https_gateway')
