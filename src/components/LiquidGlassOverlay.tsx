import React from 'react';

export const LiquidGlassOverlay: React.FC = () => {
  return (
    <svg className="fixed top-0 left-0 w-0 h-0 pointer-events-none z-[-1]" aria-hidden="true">
      <defs>
        {/* Dynamic Fluid Refraction Filter */}
        <filter id="fluid-lens-distortion" x="-20%" y="-20%" width="140%" height="140%">
          <feTurbulence
            type="fractalNoise"
            baseFrequency="0.015 0.02"
            numOctaves="2"
            result="noise"
          />
          <feDisplacementMap
            in="SourceGraphic"
            in2="noise"
            scale="14"
            xChannelSelector="R"
            yChannelSelector="G"
            result="displaced"
          />
          <feSpecularLighting
            in="noise"
            surfaceScale="5"
            specularConstant="1.2"
            specularExponent="30"
            lightingColor="#ffffff"
            result="specular"
          >
            <feDistantLight azimuth="225" elevation="45" />
          </feSpecularLighting>
          <feComposite in="specular" in2="SourceGraphic" operator="in" result="specularCut" />
          <feBlend in="specularCut" in2="displaced" mode="screen" />
        </filter>

        {/* Specular Edge Lens Reflection Filter */}
        <filter id="liquid-specular-edge">
          <feGaussianBlur in="SourceAlpha" stdDeviation="3" result="blur" />
          <feSpecularLighting
            in="blur"
            surfaceScale="7"
            specularConstant="1.8"
            specularExponent="40"
            lightingColor="#ffffff"
            result="specular"
          >
            <fePointLight x="150" y="-50" z="200" />
          </feSpecularLighting>
          <feComposite in="specular" in2="SourceGraphic" operator="in" result="light" />
          <feBlend in="SourceGraphic" in2="light" mode="screen" />
        </filter>
      </defs>
    </svg>
  );
};
