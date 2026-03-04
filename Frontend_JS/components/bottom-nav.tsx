"use client"

import { Timer, BarChart3, Settings } from "lucide-react"

type NavTab = "timer" | "analytics" | "settings"

interface BottomNavProps {
  activeTab: NavTab
  onTabChange: (tab: NavTab) => void
}

const tabs: { id: NavTab; icon: typeof Timer; label: string }[] = [
  { id: "timer", icon: Timer, label: "Timer" },
  { id: "analytics", icon: BarChart3, label: "Analytics" },
  { id: "settings", icon: Settings, label: "Settings" },
]

export function BottomNav({ activeTab, onTabChange }: BottomNavProps) {
  return (
    <nav
      className="fixed bottom-6 left-1/2 -translate-x-1/2 z-50"
      role="navigation"
      aria-label="Main navigation"
    >
      <div className="flex items-center gap-2 bg-[#1C1C1E] px-3 py-2.5 rounded-full">
        {tabs.map((tab) => {
          const Icon = tab.icon
          const isActive = activeTab === tab.id
          return (
            <button
              key={tab.id}
              onClick={() => onTabChange(tab.id)}
              className={`flex items-center justify-center rounded-full transition-all duration-200 ${
                isActive
                  ? "bg-[#E0FF57] text-[#0F0F11] px-5 py-2.5 gap-2"
                  : "text-[#A1A1AA] px-3.5 py-2.5 hover:text-white"
              }`}
              aria-label={tab.label}
              aria-current={isActive ? "page" : undefined}
            >
              <Icon className="w-5 h-5" strokeWidth={2} />
              {isActive && (
                <span className="text-sm font-medium">{tab.label}</span>
              )}
            </button>
          )
        })}
      </div>
    </nav>
  )
}
