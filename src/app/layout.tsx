import type { Metadata } from 'next'
import './globals.css'

export const metadata: Metadata = {
  title: '时间记录',
  description: '日历时间记录与爱好统计',
  manifest: '/manifest.json',
}

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="zh">
      <body>{children}</body>
    </html>
  )
}
