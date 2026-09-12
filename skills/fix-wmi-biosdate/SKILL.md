---
name: fix-wmi-biosdate
description: >-
  Conserta Win32_BIOS.ReleaseDate vazio em servidores Windows (Server 2019/2022)
  em VMs Oracle Cloud / QEMU-KVM, onde o firmware entrega a data num formato que
  o WMI nao consegue parsear e devolve vazio — quebrando software (ex.: ERP OnClick)
  que le a data via biblioteca WMI/.NET e trava. Use quando: `wmic bios get ReleaseDate`
  volta vazio, ou um app crasha por ReleaseDate/BIOS date ausente, ou for preciso
  aplicar essa correcao em varios IPs. Palavras-gatilho: ReleaseDate vazio, wmic bios,
  Win32_BIOS, SMBIOS date, ERP trava sem data da BIOS, Oracle Cloud Windows.
---

# fix-wmi-biosdate

## O problema

Em VMs Windows na **Oracle Cloud** (e QEMU/KVM em geral), o firmware entrega a
BIOS Release Date como `May-22-2026` (formato `MMM-DD-YYYY`). O SMBIOS exige
`MM/DD/YYYY`, entao o WMI **rejeita e devolve `Win32_BIOS.ReleaseDate` vazio**.

O Windows Server 2019/2022 le esse campo **ao vivo do firmware**
(`GetSystemFirmwareTable('RSMB')`), nao do cache do registro — entao **patch no
registro `mssmbios\Data\SMBiosData` NAO resolve** (testado: aplica e o WMI ignora).
E o firmware e read-only de dentro da VM (nao existe `SetSystemFirmwareTable`).

Software que le a data via WMI/.NET (`System.Management`, `Get-CimInstance`,
`wmic bios`) recebe vazio e pode crashar (caso do ERP OnClick — trava o login
dos clientes).

## A solucao

Sobrescrever a classe `Win32_BIOS` no repositorio WMI: converter de **dinamica
para estatica** e injetar uma instancia com **todos os 31 campos originais
copiados** + o `ReleaseDate` preenchido com a data real (derivada de
`SMBIOSBIOSVersion` = `YYYYMMDD`, ou do registro `BIOSReleaseDate`), usando
CIM datetime com **offset LOCAL** (senao o dia desloca pelo fuso).

E idempotente e persiste via **tarefa de boot** (reaplica se um Windows Update
recompilar o MOF e reverter a classe pra dinamica).

## Pre-requisitos

- Acesso admin ao alvo. WinRM (porta **5985**) aberto — comum nessas VMs.
  (SSH normalmente fechado; RDP 3389 aberto como alternativa manual.)
- Credencial de admin (formato `DOMINIO\usuario`).
- Na maquina de origem: adicionar o alvo em `TrustedHosts` (precisa admin local).
- **IMPORTANTE (modo do Claude Code):** a escrita em Win32_BIOS/SMBIOS e barrada
  pelo *auto mode classifier* (parece spoofing de hardware). Para o Claude executar,
  o usuario precisa **sair do modo automatico** (cada acao pede aprovacao manual)
  OU rodar o script ele mesmo via RDP. Nao contornar o filtro de forma disfarcada.

## Como usar (Claude)

1. **Diagnostico** — confirmar que e este caso (nao outro bug):
   - `Win32_BIOS.ReleaseDate` vazio, MAS `SMBIOSBIOSVersion` (ex.: `20260522`) e/ou
     `HKLM\HARDWARE\DESCRIPTION\System\BIOS\BIOSReleaseDate` (ex.: `May-22-2026`) presentes.
   - Rodar `scripts/apply-remote.ps1 -DiagnoseOnly`.
2. **Aplicar** com `scripts/apply-remote.ps1` (faz backup + aplica + verifica + task + revert-on-fail).
3. **Verificar**: `Result=SUCCESS` e `Parsed` = a data certa no fuso local.
4. Pedir pro usuario **reiniciar o servico do ERP** e testar um cliente.

### Aplicar num alvo

```powershell
# na maquina de origem (admin local p/ TrustedHosts), a partir da pasta scripts\
.\apply-remote.ps1 -Target 10.250.0.6 -User 'liveonclickerp\adriano.calligioni' -Password '***'
```

Executando direto via WinRM (padrao que o Claude usou), o worker
`scripts/wmi-biosdate-fix.ps1` e o miolo — pode ser colado num
`Invoke-Command ... -ScriptBlock` ou rodado localmente no alvo via RDP.

### Diagnosticar (sem alterar)

```powershell
.\apply-remote.ps1 -Target 10.250.0.6 -User '...' -Password '...' -DiagnoseOnly
```

### Reverter (voltar Win32_BIOS pra dinamica + remover tarefa)

```powershell
.\apply-remote.ps1 -Target 10.250.0.6 -User '...' -Password '...' -Revert
```

## Rollback / recuperacao

- **Automatico**: se o verify falhar, o script ja reverte a classe pra dinamica.
- **Manual**: `-Revert` (acima).
- **Backup** no alvo: `C:\ProgramData\Fix-BiosDate\` (MOF da classe + valores originais).
- **Botao de panico** (reconstroi o WMI inteiro dos MOFs de fabrica, restaura o
  Win32_BIOS dinamico original e apaga o override):
  ```cmd
  net stop winmgmt /y
  winmgmt /resetrepository
  ```

## Notas / limites

- A **solucao definitiva** e o software cliente tolerar `ReleaseDate` vazio ou ler
  de um campo populado (`SMBIOSBIOSVersion`). Este fix e o paliativo no SO.
- Afeta o `Win32_BIOS` do sistema inteiro (todo leitor passa a ver a instancia
  estatica) — por isso copiamos TODOS os campos originais, so o ReleaseDate muda.
- Sobrevive a reboot (repositorio WMI e persistente). A tarefa de boot cobre o
  caso de um Windows Update recompilar o cimwin32.mof e reverter pra dinamica.
- Testado em: Server 2022 (10.250.0.186) e Server 2019 (10.250.0.6), VMs Oracle Cloud.

## Historico de alvos aplicados

| IP | Host | OS | Data | Resultado |
|---|---|---|---|---|
| 10.250.0.186 | ONCLICKERP-HS06 | Server 2022 | 2026-05-22 | OK (offset UTC — corrigir p/ local se preciso) |
| 10.250.0.6 | ONCLICKERP-HS01 | Server 2019 | 2026-05-22 | OK (offset local -180) |
| 10.250.0.7 | ONCLICKERP-HS02 | Server 2019 | 2026-05-22 | OK (offset local -180) |
| 10.250.0.9 | ONCLICKERP-HS03 | Server 2019 | 2026-05-22 | OK (offset local -180) |
