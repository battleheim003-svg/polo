class_name BalanceConfig
extends RefCounted

const ROLE_EXACT: float = 1.0
const ROLE_ADJACENT: float = 0.9
const ROLE_MISMATCH: float = 0.78
const ZONE_BONUS: float = 6.0
const TACTIC_BONUS: float = 7.0
const SHOT_THRESHOLD: float = 56.0
const SYNERGY_BONUS: float = 4.0
const SYNERGY_CAP: float = 8.0
const LINE_OWNER_BONUS: float = 1.5
const FATIGUE_WEIGHT: float = 18.0
const PRESSURE_WEIGHT: float = 8.0
const VARIANCE: float = 5.0
const COMMAND_DURATION_TICKS: int = 3
const COMMANDS_PER_CHUKKER: int = 1
const MAX_FOCUS: int = 100
const MAX_STAMINA: int = 100
const CHUKKER_SECONDS: int = 150
const CHUKKER_COUNT: int = 2
const MAX_EXTRA_TICKS: int = 40
const TICK_SECONDS: int = 5

const ACTION_STRIKE := "Strike"
const ACTION_PASS := "Pass"
const ACTION_HOOK := "Hook"
const ACTION_RIDE_OFF := "RideOff"
const ACTION_RECOVERY := "Recovery"
const ACTION_SHOT := "Shot"
