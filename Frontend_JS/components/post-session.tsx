"use client"

import { useState } from "react"
import { Pencil, Clock, AlertTriangle, Check } from "lucide-react"

interface PostSessionProps {
  elapsed: number
  onDone: () => void
}

function getSessionTitle() {
  const now = new Date()
  const days = [
    "Sunday",
    "Monday",
    "Tuesday",
    "Wednesday",
    "Thursday",
    "Friday",
    "Saturday",
  ]
  const day = days[now.getDay()]
  const hour = now.getHours()
  let period = "Morning"
  if (hour >= 12 && hour < 17) period = "Afternoon"
  else if (hour >= 17 && hour < 21) period = "Evening"
  else if (hour >= 21 || hour < 5) period = "Night"
  return `${day} ${period} Focus`
}

export function PostSession({ elapsed, onDone }: PostSessionProps) {
  const [title, setTitle] = useState(getSessionTitle)
  const [isEditing, setIsEditing] = useState(false)

  const focusScore = 85
  const focusPercent = 70
  const fidgetPercent = 10
  const distractionPercent = 20
  const totalMinutes = Math.max(1, Math.round(elapsed / 60))
  const distractionCount = 3

  return (
    <div className="flex flex-col min-h-[calc(100dvh-100px)] px-5 pt-14 pb-28">
      {/* Title */}
      <div className="flex items-center gap-2 mb-8">
        {isEditing ? (
          <div className="flex items-center gap-2 flex-1">
            <input
              type="text"
              value={title}
              onChange={(e) => setTitle(e.target.value)}
              className="bg-transparent text-white text-xl font-semibold border-b border-[#E0FF57] outline-none flex-1 pb-1"
              autoFocus
              onKeyDown={(e) => {
                if (e.key === "Enter") setIsEditing(false)
              }}
              onBlur={() => setIsEditing(false)}
              aria-label="Edit session title"
            />
            <button
              onClick={() => setIsEditing(false)}
              className="text-[#E0FF57]"
              aria-label="Save title"
            >
              <Check className="w-5 h-5" />
            </button>
          </div>
        ) : (
          <>
            <h1 className="text-xl font-semibold text-white text-balance">{title}</h1>
            <button
              onClick={() => setIsEditing(true)}
              className="text-[#A1A1AA] hover:text-white transition-colors"
              aria-label="Edit session title"
            >
              <Pencil className="w-4 h-4" />
            </button>
          </>
        )}
      </div>

      {/* Focus Score Card */}
      <div className="bg-[#E0FF57] rounded-[32px] p-7 mb-4">
        <p className="text-[#0F0F11]/60 text-sm font-medium mb-1">
          Focus Score
        </p>
        <div className="flex items-end gap-1 mb-6">
          <span className="text-[#0F0F11] text-7xl font-semibold leading-none tabular-nums">
            {focusScore}
          </span>
          <span className="text-[#0F0F11]/60 text-3xl font-semibold mb-1">
            %
          </span>
        </div>

        {/* Timeline Bar */}
        <div className="mb-4">
          <div className="flex rounded-full overflow-hidden h-3 gap-0.5">
            <div
              className="bg-[#22C55E] rounded-full"
              style={{ width: `${focusPercent}%` }}
              role="progressbar"
              aria-valuenow={focusPercent}
              aria-label="Focus time"
            />
            <div
              className="bg-[#F97316] rounded-full"
              style={{ width: `${fidgetPercent}%` }}
              role="progressbar"
              aria-valuenow={fidgetPercent}
              aria-label="Fidget time"
            />
            <div
              className="bg-[#EF4444] rounded-full"
              style={{ width: `${distractionPercent}%` }}
              role="progressbar"
              aria-valuenow={distractionPercent}
              aria-label="Distraction time"
            />
          </div>
        </div>

        {/* Legend */}
        <div className="flex items-center gap-4">
          <div className="flex items-center gap-1.5">
            <div className="w-2.5 h-2.5 rounded-full bg-[#22C55E]" />
            <span className="text-[#0F0F11]/70 text-xs font-medium">
              Focus {focusPercent}%
            </span>
          </div>
          <div className="flex items-center gap-1.5">
            <div className="w-2.5 h-2.5 rounded-full bg-[#F97316]" />
            <span className="text-[#0F0F11]/70 text-xs font-medium">
              Fidget {fidgetPercent}%
            </span>
          </div>
          <div className="flex items-center gap-1.5">
            <div className="w-2.5 h-2.5 rounded-full bg-[#EF4444]" />
            <span className="text-[#0F0F11]/70 text-xs font-medium">
              Distracted {distractionPercent}%
            </span>
          </div>
        </div>
      </div>

      {/* Stat Cards */}
      <div className="grid grid-cols-2 gap-3 mb-8">
        <div className="bg-[#1C1C1E] rounded-[32px] p-6 flex flex-col gap-3">
          <div className="flex items-center justify-center w-10 h-10 rounded-2xl bg-[#2A2A2C]">
            <Clock className="w-5 h-5 text-[#A1A1AA]" />
          </div>
          <div>
            <p className="text-[#A1A1AA] text-xs font-medium mb-0.5">
              Total Time
            </p>
            <p className="text-white text-2xl font-semibold tabular-nums">
              {totalMinutes}m
            </p>
          </div>
        </div>
        <div className="bg-[#1C1C1E] rounded-[32px] p-6 flex flex-col gap-3">
          <div className="flex items-center justify-center w-10 h-10 rounded-2xl bg-[#2A2A2C]">
            <AlertTriangle className="w-5 h-5 text-[#A1A1AA]" />
          </div>
          <div>
            <p className="text-[#A1A1AA] text-xs font-medium mb-0.5">
              Distractions
            </p>
            <p className="text-white text-2xl font-semibold tabular-nums">
              {distractionCount}
            </p>
          </div>
        </div>
      </div>

      {/* Done Button */}
      <button
        onClick={onDone}
        className="flex items-center justify-center bg-[#E0FF57] text-[#0F0F11] rounded-full px-16 py-4 font-medium text-base transition-all duration-200 active:scale-95 hover:brightness-110 w-full mt-auto"
      >
        Done
      </button>
    </div>
  )
}
