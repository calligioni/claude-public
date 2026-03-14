-- VIBC Schema: Variety Independent Board Council
-- Run once against the target Supabase/Postgres instance

CREATE TABLE IF NOT EXISTS vibc_decisions (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  title TEXT NOT NULL,
  description TEXT NOT NULL,
  decision_type VARCHAR(30) NOT NULL DEFAULT 'general',
  mode VARCHAR(10) NOT NULL DEFAULT 'full',
  status VARCHAR(20) NOT NULL DEFAULT 'deliberating',
  framing JSONB NOT NULL DEFAULT '{}',
  collision_map JSONB DEFAULT '{}',
  selected_option_id UUID,
  dimension_weights JSONB DEFAULT '{}',
  final_score NUMERIC(4,2),
  user_choice TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  decided_at TIMESTAMPTZ,
  metadata JSONB DEFAULT '{}'
);

CREATE TABLE IF NOT EXISTS vibc_board_inputs (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  decision_id UUID NOT NULL REFERENCES vibc_decisions(id) ON DELETE CASCADE,
  seat_number INTEGER NOT NULL CHECK (seat_number BETWEEN 1 AND 12),
  archetype VARCHAR(50) NOT NULL,
  position TEXT NOT NULL,
  reasoning TEXT NOT NULL,
  concerns TEXT[],
  conditions TEXT[],
  confidence INTEGER CHECK (confidence BETWEEN 1 AND 10),
  dissent_strength INTEGER CHECK (dissent_strength BETWEEN 0 AND 10),
  key_quote TEXT,
  raw_response JSONB DEFAULT '{}',
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(decision_id, seat_number)
);

CREATE TABLE IF NOT EXISTS vibc_options (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  decision_id UUID NOT NULL REFERENCES vibc_decisions(id) ON DELETE CASCADE,
  option_number INTEGER NOT NULL,
  title TEXT NOT NULL,
  description TEXT NOT NULL,
  core_bets TEXT[] NOT NULL,
  kill_conditions TEXT[] NOT NULL,
  reversibility_score INTEGER NOT NULL CHECK (reversibility_score BETWEEN 1 AND 10),
  scores JSONB NOT NULL DEFAULT '{}',
  weighted_total NUMERIC(4,2),
  supporting_seats INTEGER[],
  opposing_seats INTEGER[],
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(decision_id, option_number)
);

CREATE TABLE IF NOT EXISTS vibc_retrospectives (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  decision_id UUID NOT NULL REFERENCES vibc_decisions(id) ON DELETE CASCADE,
  actual_outcome TEXT NOT NULL,
  outcome_rating INTEGER CHECK (outcome_rating BETWEEN 1 AND 10),
  prediction_accuracy INTEGER CHECK (prediction_accuracy BETWEEN 1 AND 10),
  best_predictor_seat INTEGER,
  worst_predictor_seat INTEGER,
  lessons_learned TEXT[],
  surprise_factors TEXT[],
  retrospective_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(decision_id)
);

CREATE INDEX IF NOT EXISTS idx_vibc_board_inputs_decision ON vibc_board_inputs(decision_id);
CREATE INDEX IF NOT EXISTS idx_vibc_options_decision ON vibc_options(decision_id);
CREATE INDEX IF NOT EXISTS idx_vibc_decisions_status ON vibc_decisions(status);
CREATE INDEX IF NOT EXISTS idx_vibc_decisions_created ON vibc_decisions(created_at DESC);

CREATE OR REPLACE VIEW vibc_batting_average AS
SELECT
  bi.seat_number,
  bi.archetype,
  COUNT(DISTINCT r.decision_id) AS decisions_reviewed,
  AVG(r.prediction_accuracy) AS avg_prediction_accuracy,
  COUNT(*) FILTER (WHERE r.best_predictor_seat = bi.seat_number) AS times_best_predictor,
  COUNT(*) FILTER (WHERE r.worst_predictor_seat = bi.seat_number) AS times_worst_predictor
FROM vibc_board_inputs bi
JOIN vibc_retrospectives r ON r.decision_id = bi.decision_id
GROUP BY bi.seat_number, bi.archetype
ORDER BY avg_prediction_accuracy DESC;
