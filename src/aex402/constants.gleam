//// AeX402 SDK Constants
////
//// Program ID, discriminators, error codes, and other constants for the
//// AeX402 Hybrid StableSwap AMM on Solana.

import gleam/bit_array

// ============================================================================
// Program ID
// ============================================================================

/// The program ID for the AeX402 AMM program on Solana (devnet)
/// Base58: 3AMM53MsJZy2Jvf7PeHHga3bsGjWV4TSaYz29WUtcdje
pub const program_id_bytes = <<
  0x22, 0x2d, 0x7b, 0x8c, 0x45, 0x6f, 0x1a, 0x9e, 0xb3, 0xc7, 0xd8, 0xe2, 0xf5,
  0x4a, 0x6b, 0x8d, 0x1c, 0x3e, 0x5f, 0x72, 0x94, 0xa6, 0xb8, 0xca, 0xdc, 0xee,
  0x10, 0x32, 0x54, 0x76, 0x98, 0xba,
>>

// ============================================================================
// Pool Constants
// ============================================================================

/// Minimum amplification coefficient
pub const min_amp = 1

/// Maximum amplification coefficient
pub const max_amp = 100_000

/// Default swap fee in basis points (0.3%)
pub const default_fee_bps = 30

/// Admin fee percentage (50% of swap fee goes to admin)
pub const admin_fee_pct = 50

/// Minimum swap amount (in smallest token units)
pub const min_swap = 100_000

/// Minimum deposit amount (in smallest token units)
pub const min_deposit = 100_000_000

/// Maximum Newton's method iterations for stable swap math
pub const newton_iterations = 255

/// Minimum ramp duration in seconds (1 day)
pub const ramp_min_duration = 86_400

/// Commit delay for timelocked operations (1 hour)
pub const commit_delay = 3600

/// Migration fee in basis points (0.1337%)
pub const migration_fee_bps = 1337

/// Maximum tokens in an N-pool
pub const max_tokens = 8

/// Pool account size in bytes
pub const pool_size = 1024

/// NPool account size in bytes
pub const npool_size = 2048

// ============================================================================
// Analytics Constants
// ============================================================================

/// Bloom filter size in bytes (reserved)
pub const bloom_size = 128

/// Number of hourly OHLCV candles stored
pub const ohlcv_24h = 24

/// Number of daily OHLCV candles stored
pub const ohlcv_7d = 7

/// Slots per hour (~400ms * 9000 = 1 hour)
pub const slots_per_hour = 9000

/// Slots per day (24 hours)
pub const slots_per_day = 216_000

// ============================================================================
// Circuit Breaker Constants
// ============================================================================

/// Price deviation trigger in basis points (10%)
pub const cb_price_dev_bps = 1000

/// Volume multiplier trigger (10x average)
pub const cb_volume_mult = 10

/// Cooldown period in slots (~1 hour)
pub const cb_cooldown_slots = 9000

/// Auto-resume period in slots (~6 hours)
pub const cb_auto_resume_slots = 54_000

// ============================================================================
// Rate Limiting Constants
// ============================================================================

/// Slots per epoch (~5 minutes)
pub const rl_slots_per_epoch = 750

// ============================================================================
// Governance Constants
// ============================================================================

/// Voting period in slots (~3 days)
pub const gov_vote_slots = 518_400

/// Execution timelock in slots (~1 day)
pub const gov_timelock_slots = 172_800

/// Quorum requirement in basis points (10%)
pub const gov_quorum_bps = 1000

/// Pass threshold in basis points (50%)
pub const gov_threshold_bps = 5000

// ============================================================================
// ML Brain Constants
// ============================================================================

/// Q-learning discount factor
pub const ml_gamma = 0.9

/// Q-learning learning rate
pub const ml_alpha = 0.1

/// Q-learning exploration rate
pub const ml_epsilon = 0.1

/// Number of Q-learning states (3^3)
pub const ml_num_states = 27

/// Number of Q-learning actions
pub const ml_num_actions = 9

// ============================================================================
// Instruction Discriminators (8-byte, little-endian)
// ============================================================================

/// Pool creation discriminator
pub const disc_createpool = <<0xf9, 0xe3, 0xa7, 0xc8, 0xd1, 0xe4, 0xb9, 0xf2>>

/// N-token pool creation discriminator
pub const disc_createpn = <<0x1b, 0x7c, 0xc5, 0xe5, 0xbc, 0x33, 0x9c, 0x27>>

/// Initialize token 0 vault discriminator
pub const disc_initt0v = <<0x9f, 0x4a, 0x3e, 0x0f, 0x0d, 0x3b, 0x8c, 0x5e>>

/// Initialize token 1 vault discriminator
pub const disc_initt1v = <<0x8a, 0x5e, 0x2d, 0x3b, 0x1c, 0x9f, 0x4e, 0x7a>>

/// Initialize LP mint discriminator
pub const disc_initlpm = <<0xf2, 0xe7, 0xb8, 0xc5, 0xa3, 0xe9, 0xd1, 0xf4>>

/// Generic swap discriminator
pub const disc_swap = <<0xc8, 0x87, 0x75, 0xe1, 0x91, 0x9e, 0xc6, 0x82>>

/// Swap token 0 to token 1 discriminator
pub const disc_swapt0t1 = <<0x2a, 0x4e, 0xf1, 0xe0, 0xb7, 0xf2, 0x2a, 0x64>>

/// Swap token 1 to token 0 discriminator
pub const disc_swapt1t0 = <<0xc8, 0xc4, 0x75, 0xac, 0x1b, 0x13, 0x0e, 0x3a>>

/// N-token swap discriminator
pub const disc_swapn = <<0xf8, 0xe5, 0xd9, 0xb2, 0xc7, 0xe3, 0xa8, 0xf1>>

/// Migration swap 0 to 1 discriminator
pub const disc_migt0t1 = <<0xd5, 0xe9, 0xb7, 0xc3, 0xa8, 0xf1, 0xe4, 0xd2>>

/// Migration swap 1 to 0 discriminator
pub const disc_migt1t0 = <<0xb8, 0x3d, 0x39, 0x26, 0x94, 0x77, 0x88, 0x18>>

/// Add liquidity discriminator
pub const disc_addliq = <<0xa9, 0xe5, 0xd1, 0xb3, 0xf8, 0xc4, 0xe7, 0xa2>>

/// Single-sided add liquidity discriminator
pub const disc_addliq1 = <<0xe6, 0x12, 0x2e, 0x3c, 0x4e, 0x8b, 0xc9, 0x51>>

/// N-token add liquidity discriminator
pub const disc_addliqn = <<0xf6, 0xe4, 0xe9, 0xb1, 0xa8, 0xc2, 0xf7, 0xe3>>

/// Remove liquidity discriminator
pub const disc_remliq = <<0x02, 0xf9, 0xc5, 0x75, 0x2c, 0xbc, 0x54, 0x2e>>

/// N-token remove liquidity discriminator
pub const disc_remliqn = <<0xb4, 0xb1, 0xe9, 0xd7, 0xc5, 0xa2, 0xe8, 0xb3>>

/// Set pause discriminator
pub const disc_setpause = <<0xc9, 0x6e, 0x0d, 0x7e, 0x2b, 0x76, 0x75, 0xe0>>

/// Update fee discriminator
pub const disc_updfee = <<0x4a, 0x1f, 0x9d, 0x7c, 0x5b, 0x2e, 0x3a, 0x8f>>

/// Withdraw fee discriminator
pub const disc_wdrawfee = <<0xf8, 0xe7, 0xb1, 0xc8, 0xa2, 0xd3, 0xe5, 0xf9>>

/// Commit amp change discriminator
pub const disc_commitamp = <<0xc4, 0xe2, 0xb8, 0xa5, 0xf7, 0xe3, 0xd9, 0xc1>>

/// Ramp amp discriminator
pub const disc_rampamp = <<0x6a, 0x8e, 0x2d, 0x7b, 0x3f, 0x5e, 0x1c, 0x9a>>

/// Stop ramp discriminator
pub const disc_stopramp = <<0x53, 0x10, 0xa2, 0x15, 0xbb, 0x27, 0x94, 0x3c>>

/// Initiate authority transfer discriminator
pub const disc_initauth = <<0xf4, 0xf8, 0xe1, 0xb3, 0xc9, 0xa7, 0xe2, 0xf5>>

/// Complete authority transfer discriminator
pub const disc_complauth = <<0xf5, 0xe1, 0xe9, 0xb7, 0xa4, 0xd2, 0xe8, 0xf6>>

/// Cancel authority transfer discriminator
pub const disc_cancelauth = <<0xf6, 0xe8, 0xb2, 0xd5, 0xc1, 0xa9, 0xe3, 0xf7>>

/// Create farm discriminator
pub const disc_createfarm = <<0x5c, 0x5d, 0x1a, 0x2f, 0x8e, 0x0c, 0x7b, 0x6d>>

/// Stake LP discriminator
pub const disc_stakelp = <<0xf7, 0xe2, 0xb9, 0xb3, 0xa7, 0xe1, 0xd4, 0xf8>>

/// Unstake LP discriminator
pub const disc_unstakelp = <<0xbc, 0xf8, 0x34, 0x4e, 0x65, 0xbf, 0x66, 0x41>>

/// Claim farm rewards discriminator
pub const disc_claimfarm = <<0x9b, 0xec, 0xd6, 0xe0, 0xb7, 0x62, 0x75, 0x07>>

/// Lock LP discriminator
pub const disc_locklp = <<0xec, 0x8c, 0x02, 0x5f, 0x01, 0x83, 0xfb, 0xfe>>

/// Claim unlocked LP discriminator
pub const disc_claimulp = <<0x1e, 0x8b, 0xe8, 0x5c, 0xf4, 0x93, 0x85, 0xca>>

/// Create lottery discriminator
pub const disc_createlot = <<0x3c, 0x79, 0x72, 0x65, 0x74, 0x74, 0x6f, 0x6c>>

/// Enter lottery discriminator
pub const disc_enterlot = <<0xfc, 0x48, 0xef, 0x4e, 0x3a, 0x38, 0x95, 0xe7>>

/// Draw lottery discriminator
pub const disc_drawlot = <<0x11, 0xbc, 0x7c, 0x4d, 0x5a, 0x22, 0x61, 0x13>>

/// Claim lottery prize discriminator
pub const disc_claimlot = <<0xf4, 0x3c, 0x9f, 0x15, 0x3f, 0x5e, 0x7b, 0x7e>>

/// Initialize registry discriminator
pub const disc_initreg = <<0x18, 0x07, 0x60, 0xf5, 0xd4, 0xc3, 0xb2, 0xa1>>

/// Register pool discriminator
pub const disc_regpool = <<0x29, 0x18, 0x07, 0xf6, 0xe5, 0xd4, 0xc3, 0xb2>>

/// Unregister pool discriminator
pub const disc_unregpool = <<0x30, 0x29, 0x18, 0x07, 0xf6, 0xe5, 0xd4, 0xc3>>

/// Get TWAP discriminator
pub const disc_gettwap = <<0x01, 0x74, 0x65, 0x67, 0x61, 0x70, 0x77, 0x74>>

/// Set circuit breaker discriminator
pub const disc_setcb = <<0x01, 0xcb, 0x01, 0xcb, 0x01, 0xcb, 0x01, 0xcb>>

/// Reset circuit breaker discriminator
pub const disc_resetcb = <<0x02, 0xcb, 0x02, 0xcb, 0x02, 0xcb, 0x02, 0xcb>>

/// Set rate limit discriminator
pub const disc_setrl = <<0x6c, 0x72, 0x01, 0x6c, 0x72, 0x01, 0x6c, 0x72>>

/// Set oracle discriminator
pub const disc_setoracle = <<0x04, 0x03, 0x02, 0x01, 0x6c, 0x63, 0x72, 0x6f>>

/// Governance proposal discriminator
pub const disc_govprop = <<0x00, 0x70, 0x6f, 0x72, 0x70, 0x76, 0x6f, 0x67>>

/// Governance vote discriminator
pub const disc_govvote = <<0x00, 0x65, 0x74, 0x6f, 0x76, 0x76, 0x6f, 0x67>>

/// Governance execute discriminator
pub const disc_govexec = <<0x63, 0x65, 0x78, 0x65, 0x76, 0x6f, 0x67, 0x00>>

/// Governance cancel discriminator
pub const disc_govcncl = <<0x6c, 0x63, 0x6e, 0x63, 0x76, 0x6f, 0x67, 0x00>>

/// Initialize orderbook discriminator
pub const disc_initbook = <<0x6b, 0x6f, 0x6f, 0x62, 0x74, 0x69, 0x6e, 0x69>>

/// Place order discriminator
pub const disc_placeord = <<0x64, 0x72, 0x6f, 0x65, 0x63, 0x61, 0x6c, 0x70>>

/// Cancel order discriminator
pub const disc_cancelord = <<0x72, 0x6f, 0x6c, 0x65, 0x63, 0x6e, 0x61, 0x63>>

/// Fill order discriminator
pub const disc_fillord = <<0x65, 0x64, 0x72, 0x6f, 0x6c, 0x6c, 0x69, 0x66>>

/// Initialize CL pool discriminator
pub const disc_initclpl = <<0x01, 0x01, 0x6c, 0x6f, 0x6f, 0x70, 0x6c, 0x63>>

/// CL mint discriminator
pub const disc_clmint = <<0x01, 0x01, 0x74, 0x6e, 0x69, 0x6d, 0x6c, 0x63>>

/// CL burn discriminator
pub const disc_clburn = <<0x01, 0x01, 0x6e, 0x72, 0x75, 0x62, 0x6c, 0x63>>

/// CL collect discriminator
pub const disc_clcollect = <<0x63, 0x65, 0x6c, 0x6c, 0x6f, 0x63, 0x6c, 0x63>>

/// CL swap discriminator
pub const disc_clswap = <<0x01, 0x01, 0x70, 0x61, 0x77, 0x73, 0x6c, 0x63>>

/// Flash loan discriminator
pub const disc_flashloan = <<0x61, 0x6f, 0x6c, 0x68, 0x73, 0x61, 0x6c, 0x66>>

/// Flash loan repay discriminator
pub const disc_flashrepy = <<0x70, 0x65, 0x72, 0x68, 0x73, 0x61, 0x6c, 0x66>>

/// Multi-hop swap discriminator
pub const disc_multihop = <<0x70, 0x6f, 0x68, 0x69, 0x74, 0x6c, 0x75, 0x6d>>

/// Initialize ML brain discriminator
pub const disc_initml = <<0x72, 0x62, 0x6c, 0x6d, 0x74, 0x69, 0x6e, 0x69>>

/// Configure ML brain discriminator
pub const disc_cfgml = <<0x61, 0x72, 0x62, 0x6c, 0x6d, 0x67, 0x66, 0x63>>

/// Train ML discriminator
pub const disc_trainml = <<0x00, 0x6c, 0x6d, 0x6e, 0x69, 0x61, 0x72, 0x74>>

/// Apply ML action discriminator
pub const disc_applyml = <<0x00, 0x6c, 0x6d, 0x79, 0x6c, 0x70, 0x70, 0x61>>

/// Log ML state discriminator
pub const disc_logml = <<0x61, 0x74, 0x73, 0x6c, 0x6d, 0x67, 0x6f, 0x6c>>

/// Transfer hook execute discriminator
pub const disc_th_exec = <<0x69, 0x25, 0x65, 0xc5, 0x4b, 0xfb, 0x66, 0x1a>>

/// Transfer hook init discriminator
pub const disc_th_init = <<0x2b, 0x22, 0x0d, 0x31, 0xa7, 0x58, 0xeb, 0xeb>>

// ============================================================================
// Account Discriminators (8-byte ASCII strings)
// ============================================================================

/// Pool account discriminator: "POOLSWAP"
pub const account_disc_pool = <<0x50, 0x4f, 0x4f, 0x4c, 0x53, 0x57, 0x41, 0x50>>

/// NPool account discriminator: "NPOOLSWA"
pub const account_disc_npool = <<0x4e, 0x50, 0x4f, 0x4f, 0x4c, 0x53, 0x57, 0x41>>

/// Farm account discriminator: "FARMSWAP"
pub const account_disc_farm = <<0x46, 0x41, 0x52, 0x4d, 0x53, 0x57, 0x41, 0x50>>

/// UserFarm account discriminator: "UFARMSWA"
pub const account_disc_ufarm = <<0x55, 0x46, 0x41, 0x52, 0x4d, 0x53, 0x57, 0x41>>

/// Lottery account discriminator: "LOTTERY!"
pub const account_disc_lottery = <<0x4c, 0x4f, 0x54, 0x54, 0x45, 0x52, 0x59, 0x21>>

/// LotteryEntry account discriminator: "LOTENTRY"
pub const account_disc_lotentry = <<0x4c, 0x4f, 0x54, 0x45, 0x4e, 0x54, 0x52, 0x59>>

/// Registry account discriminator: "REGISTRY"
pub const account_disc_registry = <<0x52, 0x45, 0x47, 0x49, 0x53, 0x54, 0x52, 0x59>>

/// ML Brain account discriminator: "MLBRAIN!"
pub const account_disc_mlbrain = <<0x4d, 0x4c, 0x42, 0x52, 0x41, 0x49, 0x4e, 0x21>>

/// CL Pool account discriminator: "CLPOOL!!"
pub const account_disc_clpool = <<0x43, 0x4c, 0x50, 0x4f, 0x4f, 0x4c, 0x21, 0x21>>

/// CL Position account discriminator: "CLPOSIT!"
pub const account_disc_clpos = <<0x43, 0x4c, 0x50, 0x4f, 0x53, 0x49, 0x54, 0x21>>

/// Orderbook account discriminator: "ORDERBOK"
pub const account_disc_book = <<0x4f, 0x52, 0x44, 0x45, 0x52, 0x42, 0x4f, 0x4b>>

/// AI Fee manager discriminator: "AIFEE!!!"
pub const account_disc_aifee = <<0x41, 0x49, 0x46, 0x45, 0x45, 0x21, 0x21, 0x21>>

/// Transfer hook metadata discriminator: "THMETA!!"
pub const account_disc_thmeta = <<0x54, 0x48, 0x4d, 0x45, 0x54, 0x41, 0x21, 0x21>>

/// Governance proposal discriminator: "GOVPROP!"
pub const account_disc_govprop = <<0x47, 0x4f, 0x56, 0x50, 0x52, 0x4f, 0x50, 0x21>>

/// Governance vote discriminator: "GOVVOTE!"
pub const account_disc_govvote = <<0x47, 0x4f, 0x56, 0x56, 0x4f, 0x54, 0x45, 0x21>>

// ============================================================================
// Error Codes
// ============================================================================

/// Error code type
pub type AeX402Error {
  /// Pool is paused
  ErrPaused
  /// Invalid amplification coefficient
  ErrInvalidAmp
  /// Math overflow
  ErrMathOverflow
  /// Zero amount
  ErrZeroAmount
  /// Slippage exceeded
  ErrSlippageExceeded
  /// Invalid invariant or PDA mismatch
  ErrInvalidInvariant
  /// Insufficient liquidity
  ErrInsufficientLiquidity
  /// Vault mismatch
  ErrVaultMismatch
  /// Expired or ended
  ErrExpired
  /// Already initialized
  ErrAlreadyInitialized
  /// Unauthorized
  ErrUnauthorized
  /// Ramp constraint violated
  ErrRampConstraint
  /// Tokens are locked
  ErrLocked
  /// Farming error
  ErrFarmingError
  /// Invalid account owner
  ErrInvalidOwner
  /// Invalid account discriminator
  ErrInvalidDiscriminator
  /// CPI call failed
  ErrCpiFailed
  /// Orderbook/registry is full
  ErrFull
  /// Circuit breaker triggered
  ErrCircuitBreaker
  /// Oracle price validation failed
  ErrOracleError
  /// Rate limit exceeded
  ErrRateLimit
  /// Governance error
  ErrGovernanceError
  /// Orderbook error
  ErrOrderError
  /// Invalid tick
  ErrTickError
  /// Invalid price range
  ErrRangeError
  /// Flash loan error
  ErrFlashError
  /// Cooldown period not elapsed
  ErrCooldown
  /// MEV protection triggered
  ErrMevProtection
  /// Stale data
  ErrStaleData
  /// ML bias error
  ErrBiasError
  /// Invalid duration
  ErrDurationError
}

/// Convert error code number to AeX402Error type
pub fn error_from_code(code: Int) -> Result(AeX402Error, Nil) {
  case code {
    6000 -> Ok(ErrPaused)
    6001 -> Ok(ErrInvalidAmp)
    6002 -> Ok(ErrMathOverflow)
    6003 -> Ok(ErrZeroAmount)
    6004 -> Ok(ErrSlippageExceeded)
    6005 -> Ok(ErrInvalidInvariant)
    6006 -> Ok(ErrInsufficientLiquidity)
    6007 -> Ok(ErrVaultMismatch)
    6008 -> Ok(ErrExpired)
    6009 -> Ok(ErrAlreadyInitialized)
    6010 -> Ok(ErrUnauthorized)
    6011 -> Ok(ErrRampConstraint)
    6012 -> Ok(ErrLocked)
    6013 -> Ok(ErrFarmingError)
    6014 -> Ok(ErrInvalidOwner)
    6015 -> Ok(ErrInvalidDiscriminator)
    6016 -> Ok(ErrCpiFailed)
    6017 -> Ok(ErrFull)
    6018 -> Ok(ErrCircuitBreaker)
    6019 -> Ok(ErrOracleError)
    6020 -> Ok(ErrRateLimit)
    6021 -> Ok(ErrGovernanceError)
    6022 -> Ok(ErrOrderError)
    6023 -> Ok(ErrTickError)
    6024 -> Ok(ErrRangeError)
    6025 -> Ok(ErrFlashError)
    6026 -> Ok(ErrCooldown)
    6027 -> Ok(ErrMevProtection)
    6028 -> Ok(ErrStaleData)
    6029 -> Ok(ErrBiasError)
    6030 -> Ok(ErrDurationError)
    _ -> Error(Nil)
  }
}

/// Convert AeX402Error to error code number
pub fn error_to_code(error: AeX402Error) -> Int {
  case error {
    ErrPaused -> 6000
    ErrInvalidAmp -> 6001
    ErrMathOverflow -> 6002
    ErrZeroAmount -> 6003
    ErrSlippageExceeded -> 6004
    ErrInvalidInvariant -> 6005
    ErrInsufficientLiquidity -> 6006
    ErrVaultMismatch -> 6007
    ErrExpired -> 6008
    ErrAlreadyInitialized -> 6009
    ErrUnauthorized -> 6010
    ErrRampConstraint -> 6011
    ErrLocked -> 6012
    ErrFarmingError -> 6013
    ErrInvalidOwner -> 6014
    ErrInvalidDiscriminator -> 6015
    ErrCpiFailed -> 6016
    ErrFull -> 6017
    ErrCircuitBreaker -> 6018
    ErrOracleError -> 6019
    ErrRateLimit -> 6020
    ErrGovernanceError -> 6021
    ErrOrderError -> 6022
    ErrTickError -> 6023
    ErrRangeError -> 6024
    ErrFlashError -> 6025
    ErrCooldown -> 6026
    ErrMevProtection -> 6027
    ErrStaleData -> 6028
    ErrBiasError -> 6029
    ErrDurationError -> 6030
  }
}

/// Get error message for an AeX402Error
pub fn error_message(error: AeX402Error) -> String {
  case error {
    ErrPaused -> "Pool is paused"
    ErrInvalidAmp -> "Invalid amplification coefficient"
    ErrMathOverflow -> "Math overflow"
    ErrZeroAmount -> "Zero amount"
    ErrSlippageExceeded -> "Slippage exceeded"
    ErrInvalidInvariant -> "Invalid invariant or PDA mismatch"
    ErrInsufficientLiquidity -> "Insufficient liquidity"
    ErrVaultMismatch -> "Vault mismatch"
    ErrExpired -> "Expired or ended"
    ErrAlreadyInitialized -> "Already initialized"
    ErrUnauthorized -> "Unauthorized"
    ErrRampConstraint -> "Ramp constraint violated"
    ErrLocked -> "Tokens are locked"
    ErrFarmingError -> "Farming error"
    ErrInvalidOwner -> "Invalid account owner"
    ErrInvalidDiscriminator -> "Invalid account discriminator"
    ErrCpiFailed -> "CPI call failed"
    ErrFull -> "Orderbook/registry is full"
    ErrCircuitBreaker -> "Circuit breaker triggered"
    ErrOracleError -> "Oracle price validation failed"
    ErrRateLimit -> "Rate limit exceeded"
    ErrGovernanceError -> "Governance error"
    ErrOrderError -> "Orderbook error"
    ErrTickError -> "Invalid tick"
    ErrRangeError -> "Invalid price range"
    ErrFlashError -> "Flash loan error"
    ErrCooldown -> "Cooldown period not elapsed"
    ErrMevProtection -> "MEV protection triggered"
    ErrStaleData -> "Stale data"
    ErrBiasError -> "ML bias error"
    ErrDurationError -> "Invalid duration"
  }
}

// ============================================================================
// TWAP Windows
// ============================================================================

/// TWAP window type
pub type TwapWindow {
  /// 1 hour window
  Hour1
  /// 4 hour window
  Hour4
  /// 24 hour window
  Hour24
  /// 7 day window
  Day7
}

/// Convert TwapWindow to byte value
pub fn twap_window_to_byte(window: TwapWindow) -> Int {
  case window {
    Hour1 -> 0
    Hour4 -> 1
    Hour24 -> 2
    Day7 -> 3
  }
}

/// Convert byte value to TwapWindow
pub fn twap_window_from_byte(byte: Int) -> Result(TwapWindow, Nil) {
  case byte {
    0 -> Ok(Hour1)
    1 -> Ok(Hour4)
    2 -> Ok(Hour24)
    3 -> Ok(Day7)
    _ -> Error(Nil)
  }
}
