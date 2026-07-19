import type { Metadata } from "next";
import { VT323, Share_Tech_Mono } from "next/font/google";
import "./globals.css";

const vt323 = VT323({
  weight: "400",
  subsets: ["latin"],
  variable: "--font-vt323",
  fallback: ["monospace"],
  adjustFontFallback: false,
});

const shareTechMono = Share_Tech_Mono({
  weight: "400",
  subsets: ["latin"],
  variable: "--font-share-tech-mono",
  fallback: ["ui-monospace", "monospace"],
  adjustFontFallback: false,
});

export const metadata: Metadata = {
  title: "WIRE — The command layer for finance",
  description:
    "Buy, sell, and send tokenized stocks on Robinhood Chain. Just tweet @wirebotRH.",
  openGraph: {
    title: "WIRE",
    description: "Trade tokenized stocks by tweeting. No app. No wallet setup.",
    images: ["/seo/banner.png"],
  },
  twitter: {
    card: "summary_large_image",
    title: "WIRE",
    description: "Trade tokenized stocks by tweeting. No app. No wallet setup.",
    images: ["/seo/banner.png"],
  },
  icons: {
    shortcut: "/seo/favicon-32.png",
    icon: [
      { url: "/seo/favicon-16.png", sizes: "16x16", type: "image/png" },
      { url: "/seo/favicon-32.png", sizes: "32x32", type: "image/png" },
    ],
    apple: "/seo/favicon.png",
  },
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html
      lang="en"
      className={`${vt323.variable} ${shareTechMono.variable} dark`}
    >
      <body>{children}</body>
    </html>
  );
}
