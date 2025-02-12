module Sample where

import           Clash.Prelude
import           Data.Word     (Word32)

createDomain vSystem {vName = "System100", vResetPolarity = ActiveLow, vPeriod = hzToPeriod 100e6}

---------------------------------
type MainInput =
  () -- uart_rx

type MainOutput =
  (Unsigned 8) -- led

{-# ANN
  topEntity
  ( Synthesize
      { t_name = "topEntity",
        t_inputs = [PortName "clk", PortName "rst_n"],
        t_output = PortName "led"
      }
  )
  #-}

type MainState = Word32

main :: MainState -> MainInput -> (MainState, MainOutput)
main s _ = (s + 1, 256 - (fromIntegral $ s `div` 10000000))

mainM :: (HiddenClockResetEnable dom) => Signal dom MainInput -> Signal dom MainOutput
mainM = mealy main 0

topEntity ::
  Clock System100 ->
  Reset System100 ->
  Signal System100 MainInput ->
  Signal System100 MainOutput
topEntity c r i = withClockResetEnable c r enableGen (mainM i)
