import type { Metadata, Viewport } from 'next'
import { Plus_Jakarta_Sans } from 'next/font/google'

import './globals.css'

const plusJakarta = Plus_Jakarta_Sans({
  subsets: ['latin'],
  variable: '--font-plus-jakarta',
})

export const metadata: Metadata = {
  title: 'FocusFlow - Productivity & Focus Tracker',
  description: 'Track your focus sessions, monitor distractions, and build better study habits with sensor-based productivity tracking.',
}

export const viewport: Viewport = {
  themeColor: '#0F0F11',
  width: 'device-width',
  initialScale: 1,
  maximumScale: 1,
  userScalable: false,
}

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode
}>) {
  return (
    <html lang="en" className="dark">
      <body className={`${plusJakarta.variable} font-sans antialiased`}>{children}</body>
    </html>
  )
}
