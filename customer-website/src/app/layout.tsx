import type { Metadata } from 'next';
import './globals.css';
export const metadata: Metadata = { title: 'TurboTronix Mobile Care', description: 'Doorstep mobile repair and spare parts service' };
export default function RootLayout({ children }: Readonly<{ children: React.ReactNode }>) {
  return <html lang="en"><body>{children}</body></html>;
}
