"use client";

import Link from "next/link";
import { usePathname } from "next/navigation";
import { DOC_GROUPS } from "@/lib/docs";

export function DocsSidebar() {
  const pathname = usePathname();

  return (
    <nav
      aria-label="Documentation"
      className="lg:sticky lg:top-24 lg:max-h-[calc(100vh-8rem)] lg:overflow-y-auto pb-6"
    >
      {DOC_GROUPS.map((group) => (
        <div key={group.label} className="mb-9">
          <div className="font-mono text-sm text-wire-muted tracking-[0.3em] mb-4">
            {"// "}
            {group.label}
          </div>
          <ul className="space-y-1">
            {group.pages.map((page) => {
              const href = `/docs/${page.slug}`;
              const active = pathname === href;
              return (
                <li key={page.slug}>
                  <Link
                    href={href}
                    aria-current={active ? "page" : undefined}
                    className={
                      "flex items-center gap-2.5 font-mono text-base px-3 py-2 border-l-2 transition-all " +
                      (active
                        ? "border-wire-cyan text-wire-cyan glow-cyan bg-wire-card"
                        : "border-transparent text-wire-cyan/85 hover:text-wire-cyan hover:border-wire-border")
                    }
                  >
                    <span className={active ? "opacity-100" : "opacity-0"}>▸</span>
                    {page.title}
                  </Link>
                </li>
              );
            })}
          </ul>
        </div>
      ))}
    </nav>
  );
}
