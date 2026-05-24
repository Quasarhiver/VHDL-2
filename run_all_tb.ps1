# =============================================================================
# run_all_tb.ps1  -  Lance toutes les simulations GHDL du projet LogiGame
# Usage     : .\run_all_tb.ps1
# Prerequis : ghdl accessible dans le PATH  (https://github.com/ghdl/ghdl)
# =============================================================================

$ROOT = $PSScriptRoot
$SIM  = "$ROOT\sim_work"
$GHDL = "ghdl"
$STD  = "--std=08"

$passCount = 0
$failCount = 0
$log       = @()

New-Item -ItemType Directory -Force -Path $SIM | Out-Null

# -----------------------------------------------------------------------------
function Invoke-TB {
    param(
        [string]   $Name,
        [string]   $Entity,
        [string[]] $Files,
        [string]   $StopTime = "1ms"
    )

    $dir = "$SIM\$Name"
    New-Item -ItemType Directory -Force -Path $dir | Out-Null

    Write-Host ""
    Write-Host "===== $Name =====" -ForegroundColor Cyan

    # Analyse
    foreach ($f in $Files) {
        & $GHDL -a $STD "--workdir=$dir" $f
        if ($LASTEXITCODE -ne 0) {
            Write-Host "  [ECHEC] analyse : $f" -ForegroundColor Red
            return "FAIL"
        }
    }

    # Elaboration
    & $GHDL -e $STD "--workdir=$dir" $Entity
    if ($LASTEXITCODE -ne 0) {
        Write-Host "  [ECHEC] elaboration : $Entity" -ForegroundColor Red
        return "FAIL"
    }

    # Simulation
    & $GHDL -r $STD "--workdir=$dir" $Entity "--assert-level=error" "--stop-time=$StopTime"
    if ($LASTEXITCODE -ne 0) {
        Write-Host "  --> FAIL" -ForegroundColor Red
        return "FAIL"
    }

    Write-Host "  --> PASS" -ForegroundColor Green
    return "PASS"
}

# =============================================================================
# Chemins
# =============================================================================
$P1  = "$ROOT\part1"
$P2  = "$ROOT\part2"
$P3  = "$ROOT\part3"
$P3S = "$ROOT\part3_seed"
$P3B = "$ROOT\part3_bruit"

# =============================================================================
# Testbenches
# =============================================================================
$TBs = @(

    # --- Partie 1 : UAL + Datapath + MCU controller --------------------------
    @{
        Name     = "01_tb_ual"
        Entity   = "tb_ual"
        StopTime = "500us"
        Files    = @(
            "$P1\ual.vhd",
            "$P1\tb_ual.vhd"
        )
    },
    @{
        Name     = "02_tb_datapath"
        Entity   = "tb_datapath"
        StopTime = "500us"
        Files    = @(
            "$P1\ual.vhd",
            "$P1\datapath.vhd",
            "$P1\tb_datapath.vhd"
        )
    },
    @{
        Name     = "03_tb_mcu_controller"
        Entity   = "tb_mcu_controller"
        StopTime = "500us"
        Files    = @(
            "$P1\ual.vhd",
            "$P1\datapath.vhd",
            "$P1\mcu_controller.vhd",
            "$P1\tb_mcu_controller.vhd"
        )
    },

    # --- Partie 2 : LFSR, timer, checker, score, game controller -------------
    @{
        Name     = "04_tb_lfsr4"
        Entity   = "tb_lfsr4"
        StopTime = "20ms"     # 15 etats x 100000 cycles x 10ns = 15ms
        Files    = @(
            "$P2\lfsr4.vhd",
            "$P2\tb_lfsr4.vhd"
        )
    },
    @{
        Name     = "05_tb_response_checker"
        Entity   = "tb_response_checker"
        StopTime = "500us"
        Files    = @(
            "$P2\response_checker.vhd",
            "$P2\tb_response_checker.vhd"
        )
    },
    @{
        Name     = "06_tb_difficulty_timer"
        Entity   = "tb_difficulty_timer"
        StopTime = "20ms"
        Files    = @(
            "$P2\difficulty_timer.vhd",
            "$P2\score_counter.vhd",
            "$P2\tb_difficulty_timer_and_score.vhd"
        )
    },
    @{
        Name     = "06b_tb_score_counter"
        Entity   = "tb_score_counter"
        StopTime = "1ms"
        Files    = @(
            "$P2\difficulty_timer.vhd",
            "$P2\score_counter.vhd",
            "$P2\tb_difficulty_timer_and_score.vhd"
        )
    },
    @{
        Name     = "07_tb_game_controller"
        Entity   = "tb_game_controller"
        StopTime = "20ms"     # test complet ~6ms de temps simule
        Files    = @(
            "$P2\lfsr4.vhd",
            "$P2\difficulty_timer.vhd",
            "$P2\score_counter.vhd",
            "$P2\response_checker.vhd",
            "$P2\game_controller.vhd",
            "$P2\tb_game_controller.vhd"
        )
    },

    # --- Partie 3 : MCU LFSR program + top-level integration -----------------
    @{
        Name     = "08_tb_mcu_lfsr_program"
        Entity   = "tb_mcu_lfsr_program"
        StopTime = "50ms"     # 1200us initial + 16 x 2ms = 33ms
        Files    = @(
            "$P1\ual.vhd",
            "$P1\datapath.vhd",
            "$P3\mcu_lfsr_program.vhd",
            "$P3\tb_mcu_lfsr_program.vhd"
        )
    },
    @{
        Name     = "09_tb_logigame_mcu_top"
        Entity   = "tb_logigame_mcu_top"
        StopTime = "50ms"
        Files    = @(
            "$P1\ual.vhd",
            "$P1\datapath.vhd",
            "$P3\mcu_lfsr_program.vhd",
            "$P2\difficulty_timer.vhd",
            "$P2\score_counter.vhd",
            "$P2\response_checker.vhd",
            "$P3\logigame_mcu_top.vhd",
            "$P3\tb_logigame_mcu_top.vhd"
        )
    },

    # --- Partie 3 variante SEED ----------------------------------------------
    @{
        Name     = "10_tb_logigame_seed_top"
        Entity   = "tb_logigame_seed_top"
        StopTime = "50ms"     # DEB_SIM=5 donc rapide, SETTLE=2ms x3 manches
        Files    = @(
            "$P3S\button_debouncer.vhd",
            "$P1\ual.vhd",
            "$P1\datapath.vhd",
            "$P3\mcu_lfsr_program.vhd",
            "$P2\difficulty_timer.vhd",
            "$P2\score_counter.vhd",
            "$P2\response_checker.vhd",
            "$P3S\lfsr4_freerun.vhd",
            "$P3S\logigame_seed_top.vhd",
            "$P3S\tb_logigame_seed_top.vhd"
        )
    },

    # --- Partie 3 variante BRUIT (TRNG + MCU) --------------------------------
    @{
        Name     = "11_tb_logigame_trng_top"
        Entity   = "tb_logigame_trng_top"
        StopTime = "50ms"     # DEB_SIM=5 donc start_press ~200ns, SETTLE 2ms x4
        Files    = @(
            "$P3B\button_debouncer.vhd",
            "$P3B\ring_oscillator.vhd",
            "$P3B\trng.vhd",
            "$P1\ual.vhd",
            "$P1\datapath.vhd",
            "$P3\mcu_lfsr_program.vhd",
            "$P2\difficulty_timer.vhd",
            "$P2\score_counter.vhd",
            "$P2\response_checker.vhd",
            "$P3B\logigame_trng_top.vhd",
            "$P3B\tb_logigame_trng_top.vhd"
        )
    }
)

# =============================================================================
# Execution
# =============================================================================
Write-Host ""
Write-Host "================================================" -ForegroundColor Yellow
Write-Host "   LogiGame - Simulation GHDL (toutes parties)" -ForegroundColor Yellow
Write-Host "================================================" -ForegroundColor Yellow

foreach ($tb in $TBs) {
    $st = if ($tb.ContainsKey('StopTime')) { $tb.StopTime } else { "1ms" }
    $result = Invoke-TB -Name $tb.Name -Entity $tb.Entity -Files $tb.Files -StopTime $st
    $log   += [PSCustomObject]@{ Name = $tb.Name; Result = $result }
    if ($result -eq "PASS") { $passCount++ } else { $failCount++ }
}

# =============================================================================
# Résumé
# =============================================================================
Write-Host ""
Write-Host "================================================" -ForegroundColor Yellow
Write-Host "  RESUME" -ForegroundColor Yellow
Write-Host "================================================" -ForegroundColor Yellow

foreach ($r in $log) {
    if ($r.Result -eq "PASS") {
        Write-Host ("  {0,-40} PASS" -f $r.Name) -ForegroundColor Green
    } else {
        Write-Host ("  {0,-40} FAIL" -f $r.Name) -ForegroundColor Red
    }
}

Write-Host ""
Write-Host ("  PASS : {0}   FAIL : {1}   TOTAL : {2}" -f $passCount, $failCount, ($passCount + $failCount)) -ForegroundColor Yellow
Write-Host ""

if ($failCount -gt 0) { exit 1 } else { exit 0 }
