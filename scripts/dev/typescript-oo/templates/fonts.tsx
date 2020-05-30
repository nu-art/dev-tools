import * as React from 'react';
import {css} from 'emotion';


	function fontRenderer(text: string, fontFamily: string, color: string = "#000000", fontSize: number = 16) {
	return <div style={{fontFamily, display: "inline-block", color, fontSize}}>{text}</div>
}

FONTS_DECLARATION

export const globalStyleGuide = css`
FONTS_GLOBALS
`;

export const FONTS = {
	FONTS_USAGE
}