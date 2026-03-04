"use client"

import { useState } from "react"
import {
  Bell,
  Vibrate,
  Moon,
  Shield,
  ChevronRight,
  Info,
} from "lucide-react"

interface SettingToggleProps {
  icon: React.ReactNode
  label: string
  description: string
  checked: boolean
  onChange: (checked: boolean) => void
}

function SettingToggle({
  icon,
  label,
  description,
  checked,
  onChange,
}: SettingToggleProps) {
  return (
    <div className="flex items-center justify-between py-4">
      <div className="flex items-center gap-3">
        <div className="flex items-center justify-center w-9 h-9 rounded-2xl bg-[#2A2A2C]">
          {icon}
        </div>
        <div className="flex flex-col">
          <span className="text-white text-sm font-medium">{label}</span>
          <span className="text-[#A1A1AA] text-xs font-normal">
            {description}
          </span>
        </div>
      </div>
      <button
        role="switch"
        aria-checked={checked}
        onClick={() => onChange(!checked)}
        className={`relative w-12 h-7 rounded-full transition-all duration-200 ${
          checked ? "bg-[#E0FF57]" : "bg-[#2A2A2C]"
        }`}
        aria-label={`Toggle ${label}`}
      >
        <div
          className={`absolute top-0.5 left-0.5 w-6 h-6 rounded-full transition-all duration-200 ${
            checked ? "translate-x-5 bg-[#0F0F11]" : "translate-x-0 bg-[#A1A1AA]"
          }`}
        />
      </button>
    </div>
  )
}

interface SettingLinkProps {
  icon: React.ReactNode
  label: string
  description: string
}

function SettingLink({ icon, label, description }: SettingLinkProps) {
  return (
    <div className="flex items-center justify-between py-4">
      <div className="flex items-center gap-3">
        <div className="flex items-center justify-center w-9 h-9 rounded-2xl bg-[#2A2A2C]">
          {icon}
        </div>
        <div className="flex flex-col">
          <span className="text-white text-sm font-medium">{label}</span>
          <span className="text-[#A1A1AA] text-xs font-normal">
            {description}
          </span>
        </div>
      </div>
      <ChevronRight className="w-4 h-4 text-[#A1A1AA]" />
    </div>
  )
}

export function SettingsView() {
  const [notifications, setNotifications] = useState(true)
  const [haptics, setHaptics] = useState(true)
  const [dnd, setDnd] = useState(false)

  return (
    <div className="flex flex-col min-h-[calc(100dvh-100px)] px-5 pt-14 pb-28">
      <h1 className="text-2xl font-semibold text-white mb-1">Settings</h1>
      <p className="text-[#A1A1AA] text-sm font-normal mb-6">
        Customize your focus experience
      </p>

      {/* General */}
      <div className="bg-[#1C1C1E] rounded-[32px] px-5 mb-4">
        <div className="border-b border-[#2A2A2C]">
          <SettingToggle
            icon={<Bell className="w-4 h-4 text-[#A1A1AA]" />}
            label="Notifications"
            description="Session reminders"
            checked={notifications}
            onChange={setNotifications}
          />
        </div>
        <div className="border-b border-[#2A2A2C]">
          <SettingToggle
            icon={<Vibrate className="w-4 h-4 text-[#A1A1AA]" />}
            label="Haptic Feedback"
            description="Vibrations on interactions"
            checked={haptics}
            onChange={setHaptics}
          />
        </div>
        <SettingToggle
          icon={<Moon className="w-4 h-4 text-[#A1A1AA]" />}
          label="Do Not Disturb"
          description="Silence during sessions"
          checked={dnd}
          onChange={setDnd}
        />
      </div>

      {/* More */}
      <div className="bg-[#1C1C1E] rounded-[32px] px-5">
        <div className="border-b border-[#2A2A2C]">
          <SettingLink
            icon={<Shield className="w-4 h-4 text-[#A1A1AA]" />}
            label="Privacy"
            description="Data & permissions"
          />
        </div>
        <SettingLink
          icon={<Info className="w-4 h-4 text-[#A1A1AA]" />}
          label="About"
          description="Version 1.0.0"
        />
      </div>

      {/* Footer */}
      <div className="mt-auto pt-8 text-center">
        <p className="text-[#A1A1AA]/50 text-xs font-normal">
          FocusFlow v1.0.0
        </p>
      </div>
    </div>
  )
}
