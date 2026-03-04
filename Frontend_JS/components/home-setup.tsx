"use client"

import { useState, useEffect, useCallback } from "react"
import { Play } from "lucide-react"

interface HomeSetupProps {
  onStart: () => void
}

export function HomeSetup({ onStart }: HomeSetupProps) {
  const [mode, setMode] = useState<"stopwatch" | "timer">("stopwatch")
  const [timerMinutes, setTimerMinutes] = useState(25)
  const [timerSeconds, setTimerSeconds] = useState(0)

  const formatTime = useCallback((mins: number, secs: number) => {
    return `${String(mins).padStart(2, "0")}:${String(secs).padStart(2, "0")}`
  }, [])

  const adjustMinutes = useCallback((delta: number) => {
    setTimerMinutes((prev) => Math.max(0, Math.min(99, prev + delta)))
  }, [])

  const adjustSeconds = useCallback((delta: number) => {
    setTimerSeconds((prev) => {
      const next = prev + delta
      if (next < 0) return 55
      if (next >= 60) return 0
      return next
    })
  }, [])

  useEffect(() => {
    if (mode === "stopwatch") {
      setTimerMinutes(0)
      setTimerSeconds(0)
    } else {
      setTimerMinutes(25)
      setTimerSeconds(0)
    }
  }, [mode])

  return (
    <div className="flex flex-col items-center justify-between min-h-[calc(100dvh-100px)] px-6 pt-16 pb-28">
      {/* Mode Toggle */}
      <div className="flex items-center bg-[#1C1C1E] rounded-full p-1">
        <button
          onClick={() => setMode("stopwatch")}
          className={`px-5 py-2 rounded-full text-sm font-medium transition-all duration-200 ${
            mode === "stopwatch"
              ? "bg-[#E0FF57] text-[#0F0F11]"
              : "text-[#A1A1AA]"
          }`}
        >
          Stopwatch
        </button>
        <button
          onClick={() => setMode("timer")}
          className={`px-5 py-2 rounded-full text-sm font-medium transition-all duration-200 ${
            mode === "timer"
              ? "bg-[#E0FF57] text-[#0F0F11]"
              : "text-[#A1A1AA]"
          }`}
        >
          Timer
        </button>
      </div>

      {/* Time Display */}
      <div className="flex flex-col items-center gap-6">
        {mode === "timer" ? (
          <div className="flex items-center gap-3">
            <div className="flex flex-col items-center gap-2">
              <button
                onClick={() => adjustMinutes(1)}
                className="text-[#A1A1AA] hover:text-white transition-colors text-lg"
                aria-label="Increase minutes"
              >
                {"▲"}
              </button>
              <span className="text-8xl font-semibold tracking-tight text-white tabular-nums">
                {String(timerMinutes).padStart(2, "0")}
              </span>
              <button
                onClick={() => adjustMinutes(-1)}
                className="text-[#A1A1AA] hover:text-white transition-colors text-lg"
                aria-label="Decrease minutes"
              >
                {"▼"}
              </button>
            </div>
            <span className="text-8xl font-semibold text-[#A1A1AA]">:</span>
            <div className="flex flex-col items-center gap-2">
              <button
                onClick={() => adjustSeconds(5)}
                className="text-[#A1A1AA] hover:text-white transition-colors text-lg"
                aria-label="Increase seconds"
              >
                {"▲"}
              </button>
              <span className="text-8xl font-semibold tracking-tight text-white tabular-nums">
                {String(timerSeconds).padStart(2, "0")}
              </span>
              <button
                onClick={() => adjustSeconds(-5)}
                className="text-[#A1A1AA] hover:text-white transition-colors text-lg"
                aria-label="Decrease seconds"
              >
                {"▼"}
              </button>
            </div>
          </div>
        ) : (
          <span className="text-9xl font-semibold tracking-tight text-white tabular-nums">
            {formatTime(timerMinutes, timerSeconds)}
          </span>
        )}
        <p className="text-[#A1A1AA] text-sm font-normal">
          {mode === "stopwatch"
            ? "Place your phone face down to begin"
            : "Set your focus duration"}
        </p>
      </div>

      {/* Start Button */}
      <button
        onClick={onStart}
        className="flex items-center justify-center gap-3 bg-[#E0FF57] text-[#0F0F11] rounded-full px-16 py-4 font-medium text-lg transition-all duration-200 active:scale-95 hover:brightness-110 w-full max-w-xs"
      >
        <Play className="w-5 h-5 fill-current" />
        Start Focus
      </button>
    </div>
  )
}
