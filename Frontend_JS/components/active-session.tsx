"use client"

import { useState, useEffect, useRef } from "react"
import { Square, Smartphone } from "lucide-react"

interface ActiveSessionProps {
  onStop: (elapsed: number) => void
}

export function ActiveSession({ onStop }: ActiveSessionProps) {
  const [elapsed, setElapsed] = useState(0)
  const [breathing, setBreathing] = useState(false)
  const intervalRef = useRef<ReturnType<typeof setInterval> | null>(null)

  useEffect(() => {
    intervalRef.current = setInterval(() => {
      setElapsed((prev) => prev + 1)
    }, 1000)
    return () => {
      if (intervalRef.current) clearInterval(intervalRef.current)
    }
  }, [])

  useEffect(() => {
    const breatheInterval = setInterval(() => {
      setBreathing((prev) => !prev)
    }, 4000)
    return () => clearInterval(breatheInterval)
  }, [])

  const formatElapsed = (secs: number) => {
    const m = Math.floor(secs / 60)
    const s = secs % 60
    return `${String(m).padStart(2, "0")}:${String(s).padStart(2, "0")}`
  }

  return (
    <div className="flex flex-col items-center justify-between min-h-dvh bg-[#0A0A0B] px-6 py-16">
      {/* Elapsed time - subtle */}
      <div className="flex flex-col items-center gap-1">
        <span className="text-[#3A3A3C] text-xs font-medium tracking-widest uppercase">
          Session Active
        </span>
        <span className="text-[#3A3A3C] text-2xl font-semibold tabular-nums">
          {formatElapsed(elapsed)}
        </span>
      </div>

      {/* Center message */}
      <div className="flex flex-col items-center gap-6">
        <div
          className={`transition-all duration-[4000ms] ease-in-out ${
            breathing ? "opacity-40 scale-110" : "opacity-20 scale-100"
          }`}
        >
          <Smartphone className="w-12 h-12 text-[#3A3A3C] rotate-180" />
        </div>
        <p className="text-[#3A3A3C] text-base font-normal text-center leading-relaxed">
          Phone face down to focus.
        </p>
      </div>

      {/* Stop button */}
      <button
        onClick={() => {
          if (intervalRef.current) clearInterval(intervalRef.current)
          onStop(elapsed)
        }}
        className="flex items-center justify-center gap-2 border border-[#2A2A2C] text-[#A1A1AA] rounded-full px-8 py-3 text-sm font-medium transition-all duration-200 hover:border-[#4A4A4C] hover:text-white active:scale-95"
      >
        <Square className="w-3.5 h-3.5 fill-current" />
        Stop Session
      </button>
    </div>
  )
}
