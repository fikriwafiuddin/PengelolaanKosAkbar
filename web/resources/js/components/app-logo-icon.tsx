import type { SVGAttributes } from 'react';

/**
 * Monogram "KA" — logo Kost Akbar.
 */
export default function AppLogoIcon(props: SVGAttributes<SVGElement>) {
    return (
        <svg
            viewBox="0 0 32 32"
            xmlns="http://www.w3.org/2000/svg"
            aria-label="Logo Kost Akbar"
            {...props}
        >
            <text
                x="16"
                y="21.5"
                textAnchor="middle"
                fontSize="13"
                fontWeight="700"
                fontFamily="Georgia, serif"
                fill="currentColor"
            >
                KA
            </text>
        </svg>
    );
}
