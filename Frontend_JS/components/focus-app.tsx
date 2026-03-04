"use client"

import { useState, useCallback } from "react"
import { BottomNav } from "./bottom-nav"
import { HomeSetup } from "./home-setup"
import { ActiveSession } from "./active-session"
import { PostSession } from "./post-session"
import { AnalyticsView } from "./analytics-view"
import { SettingsView } from "./settings-view"

type AppView = "home" | "active" | "post-session"
type NavTab = "timer" | "analytics" | "settings"

export function FocusApp() {
  const [view, setView] = useState<AppView>("home")
  const [navTab, setNavTab] = useState<NavTab>("timer")
  const [sessionElapsed, setSessionElapsed] = useState(0)

  const handleStart = useCallback(() => {
    setView("active")
  }, [])

  const handleStop = useCallback((elapsed: number) => {
    setSessionElapsed(elapsed)
    setView("post-session")
  }, [])

  const handleDone = useCallback(() => {
    setView("home")
    setNavTab("timer")
  }, [])

  const handleTabChange = useCallback(
    (tab: NavTab) => {
      if (view === "active") return
      setNavTab(tab)
      if (view === "post-session") {
        setView("home")
      }
    },
    [view]
  )

  // Active session is full-screen with no nav
  if (view === "active") {
    return <ActiveSession onStop={handleStop} />
  }

  return (
    <div className="relative min-h-dvh bg-[#0F0F11]">
      <main>
        {view === "post-session" ? (
          <PostSession elapsed={sessionElapsed} onDone={handleDone} />
        ) : navTab === "timer" ? (
          <HomeSetup onStart={handleStart} />
        ) : navTab === "analytics" ? (
          <AnalyticsView />
        ) : (
          <SettingsView />
        )}
      </main>
      <BottomNav activeTab={navTab} onTabChange={handleTabChange} />
    </div>
  )
}
