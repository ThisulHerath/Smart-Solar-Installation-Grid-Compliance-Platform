type SolarWorkspaceGraphicProps = {
  className?: string;
};

/** Decorative, responsive solar illustration used inside workspace heroes. */
export function SolarWorkspaceGraphic({ className = '' }: SolarWorkspaceGraphicProps) {
  return (
    <svg
      className={`solar-workspace-graphic ${className}`.trim()}
      viewBox="0 0 360 220"
      role="img"
      aria-label="Solar panels generating clean energy"
    >
      <defs>
        <linearGradient id="panelFace" x1="0" y1="0" x2="1" y2="1">
          <stop offset="0" stopColor="#cde9e5" />
          <stop offset="1" stopColor="#75bfc0" />
        </linearGradient>
        <linearGradient id="landGlow" x1="0" y1="0" x2="1" y2="0">
          <stop offset="0" stopColor="#c7e994" stopOpacity=".05" />
          <stop offset="1" stopColor="#dff7b9" stopOpacity=".5" />
        </linearGradient>
        <filter id="softGlow" x="-50%" y="-50%" width="200%" height="200%">
          <feGaussianBlur stdDeviation="7" />
        </filter>
      </defs>

      <circle cx="278" cy="48" r="29" fill="#d4f083" opacity=".2" filter="url(#softGlow)" />
      <g className="solar-workspace-graphic__sun" transform="translate(278 48)" stroke="#d8f494" strokeWidth="4" strokeLinecap="round">
        <circle r="18" fill="#b9df6b" stroke="none" />
        <path d="M0-33V-26M0 26V33M-33 0H-26M26 0H33M-23-23L-18-18M18 18L23 23M23-23L18-18M-18 18L-23 23" />
      </g>

      <path d="M8 184C77 135 133 151 185 168C235 184 284 140 352 132V220H8Z" fill="url(#landGlow)" />
      <path d="M22 196C92 164 145 175 203 188C256 200 303 169 356 165" fill="none" stroke="#d7efc0" strokeWidth="2" opacity=".48" />

      <g transform="translate(58 73)">
        <path d="M91 109V135M38 135H146" stroke="#d2ece5" strokeWidth="6" strokeLinecap="round" opacity=".74" />
        <path d="M24 18H170L151 106H4Z" fill="url(#panelFace)" stroke="#e8fbf7" strokeWidth="3" />
        <path d="M52 18L39 106M83 18L77 106M114 18L115 106M145 18L152 106M15 60H161" stroke="#287b88" strokeWidth="2" opacity=".55" />
        <path d="M24 18H170L151 106H4Z" fill="none" stroke="#fff" strokeWidth="2" opacity=".32" />
        <circle cx="89" cy="60" r="8" fill="#e7f8e0" opacity=".34" />
      </g>

      <g transform="translate(244 110)" fill="none" stroke="#dff4d6" strokeWidth="3" strokeLinecap="round" opacity=".78">
        <path d="M0 28C18 12 42 12 59 28" />
        <path d="M11 35C23 24 37 24 49 35" />
        <circle cx="30" cy="42" r="3" fill="#dff4d6" stroke="none" />
      </g>
    </svg>
  );
}
