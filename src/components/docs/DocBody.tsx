import type { DocBlock } from "@/lib/docs";

function Block({ block }: { block: DocBlock }) {
  switch (block.type) {
    case "p":
      return (
        <p className="font-mono text-base text-wire-muted leading-relaxed mb-5">
          {block.text}
        </p>
      );

    case "list":
      return (
        <ul className="space-y-3 mb-6">
          {block.items.map((item) => (
            <li key={item.text} className="flex gap-3">
              <span className="font-mono text-base text-wire-cyan shrink-0">▪</span>
              <span className="font-mono text-base text-wire-muted leading-relaxed">
                {item.lead && (
                  <span className="text-wire-cyan">{item.lead} </span>
                )}
                {item.text}
              </span>
            </li>
          ))}
        </ul>
      );

    case "table":
      return (
        <div className="overflow-x-auto mb-6 border border-wire-border">
          <table className="w-full border-collapse">
            <thead>
              <tr className="bg-wire-card">
                {block.head.map((h) => (
                  <th
                    key={h}
                    className="font-mono text-xs text-wire-cyan tracking-[0.2em] text-left px-5 py-3.5 border-b border-wire-border whitespace-nowrap"
                  >
                    {h.toUpperCase()}
                  </th>
                ))}
              </tr>
            </thead>
            <tbody>
              {block.rows.map((row) => (
                <tr key={row.join("|")} className="hover:bg-wire-card transition-colors">
                  {row.map((cell, i) => (
                    <td
                      key={i}
                      className={
                        "font-mono text-base px-5 py-3.5 border-b border-wire-border align-top " +
                        (i === 0 ? "text-wire-cyan whitespace-nowrap" : "text-wire-muted")
                      }
                    >
                      {cell}
                    </td>
                  ))}
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      );

    case "code":
      return (
        <pre className="bg-wire-card border border-wire-border px-6 py-5 mb-6 overflow-x-auto font-mono text-sm text-wire-cyan leading-relaxed">
          {block.lines.join("\n")}
        </pre>
      );

    case "note":
      return (
        <div className="flex gap-3 border-l-2 border-wire-cyan bg-wire-card px-5 py-4 mb-6">
          <span className="font-mono text-base text-wire-cyan shrink-0 glow-cyan">
            [!]
          </span>
          <p className="font-mono text-base text-wire-muted leading-relaxed">
            {block.text}
          </p>
        </div>
      );
  }
}

export function DocBody({ blocks }: { blocks: DocBlock[] }) {
  return (
    <>
      {blocks.map((block, i) => (
        <Block key={i} block={block} />
      ))}
    </>
  );
}
