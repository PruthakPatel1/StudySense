"use client"

import { useMemo } from "react"
import { Flame, TrendingUp } from "lucide-react"

function generateHeatmap() {
  const weeks = 15
  const days = 7
  const data: number[][] = []
  for (let w = 0; w < weeks; w++) {
    const week: number[] = []
    for (let d = 0; d < days; d++) {
      const rand = Math.random()
      if (rand < 0.3) week.push(0)
      else if (rand < 0.55) week.push(1)
      else if (rand < 0.75) week.push(2)
      else if (rand < 0.9) week.push(3)
      else week.push(4)
    }
    data.push(week)
  }
  return data
}

const intensityColors: Record<number, string> = {
  0: "bg-[#1C1C1E]",
  1: "bg-[#1A3A1A]",
  2: "bg-[#2A5A2A]",
  3: "bg-[#4A9A4A]",
  4: "bg-[#9AFA90]",
}

const recentSessions = [
  {
    id: 1,
    date: "Today",
    name: "Friday Afternoon Focus",
    score: 92,
    duration: "45m",
  },
  {
    id: 2,
    date: "Yesterday",
    name: "Thursday Night Study",
    score: 78,
    duration: "60m",
  },
  {
    id: 3,
    date: "Feb 12",
    name: "Wednesday Morning Flow",
    score: 85,
    duration: "30m",
  },
  {
    id: 4,
    date: "Feb 11",
    name: "Tuesday Evening Focus",
    score: 64,
    duration: "25m",
  },
  {
    id: 5,
    date: "Feb 10",
    name: "Monday Afternoon Push",
    score: 91,
    duration: "50m",
  },
]

function getScoreColor(score: number) {
  if (score >= 85) return "text-[#9AFA90]"
  if (score >= 70) return "text-[#E0FF57]"
  return "text-[#F97316]"
}

export function AnalyticsView() {
  const heatmap = useMemo(() => generateHeatmap(), [])

  const totalSessions = 47
  const currentStreak = 5
  const avgScore = 82

  return (
    <div className="flex flex-col min-h-[calc(100dvh-100px)] px-5 pt-14 pb-28">
      {/* Header */}
      <h1 className="text-2xl font-semibold text-white mb-1">Analytics</h1>
      <p className="text-[#A1A1AA] text-sm font-normal mb-6">
        Your focus journey at a glance
      </p>

      {/* Stats Row */}
      <div className="flex gap-3 mb-6">
        <div className="flex-1 bg-[#1C1C1E] rounded-2xl p-4 flex flex-col gap-1">
          <div className="flex items-center gap-1.5">
            <Flame className="w-3.5 h-3.5 text-[#F97316]" />
            <span className="text-[#A1A1AA] text-xs font-medium">Streak</span>
          </div>
          <span className="text-white text-xl font-semibold tabular-nums">
            {currentStreak} days
          </span>
        </div>
        <div className="flex-1 bg-[#1C1C1E] rounded-2xl p-4 flex flex-col gap-1">
          <div className="flex items-center gap-1.5">
            <TrendingUp className="w-3.5 h-3.5 text-[#9AFA90]" />
            <span className="text-[#A1A1AA] text-xs font-medium">
              Avg Score
            </span>
          </div>
          <span className="text-white text-xl font-semibold tabular-nums">
            {avgScore}%
          </span>
        </div>
        <div className="flex-1 bg-[#1C1C1E] rounded-2xl p-4 flex flex-col gap-1">
          <span className="text-[#A1A1AA] text-xs font-medium">Sessions</span>
          <span className="text-white text-xl font-semibold tabular-nums">
            {totalSessions}
          </span>
        </div>
      </div>

      {/* Heatmap */}
      <div className="bg-[#1C1C1E] rounded-[32px] p-5 mb-6">
        <h2 className="text-white text-base font-semibold mb-1">
          Focus Activity
        </h2>
        <p className="text-[#A1A1AA] text-xs font-normal mb-4">
          Last 15 weeks
        </p>
        <div className="flex gap-[3px] overflow-x-auto pb-2" role="img" aria-label="Focus activity heatmap showing session intensity over the last 15 weeks">
          {heatmap.map((week, wi) => (
            <div key={wi} className="flex flex-col gap-[3px]">
              {week.map((intensity, di) => (
                <div
                  key={`${wi}-${di}`}
                  className={`w-[18px] h-[18px] rounded-[4px] ${intensityColors[intensity]} transition-colors`}
                />
              ))}
            </div>
          ))}
        </div>
        {/* Legend */}
        <div className="flex items-center gap-2 mt-3">
          <span className="text-[#A1A1AA] text-xs">Less</span>
          {[0, 1, 2, 3, 4].map((i) => (
            <div
              key={i}
              className={`w-3 h-3 rounded-[3px] ${intensityColors[i]}`}
            />
          ))}
          <span className="text-[#A1A1AA] text-xs">More</span>
        </div>
      </div>

      {/* Recent Sessions */}
      <h2 className="text-white text-base font-semibold mb-3">
        Recent Sessions
      </h2>
      <div className="flex flex-col gap-3">
        {recentSessions.map((session) => (
          <div
            key={session.id}
            className="bg-[#1C1C1E] rounded-[32px] p-5 flex items-center justify-between"
          >
            <div className="flex flex-col gap-0.5">
              <span className="text-[#A1A1AA] text-xs font-normal">
                {session.date}
              </span>
              <span className="text-white text-sm font-medium">
                {session.name}
              </span>
              <span className="text-[#A1A1AA] text-xs font-normal">
                {session.duration}
              </span>
            </div>
            <div className="flex flex-col items-end">
              <span
                className={`text-2xl font-semibold tabular-nums ${getScoreColor(session.score)}`}
              >
                {session.score}%
              </span>
            </div>
          </div>
        ))}
      </div>
    </div>
  )
}
