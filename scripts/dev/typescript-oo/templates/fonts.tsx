import * as React from 'react';


function fontRenderer(text: string, fontFamily: string, color: string = '#000000', fontSize: number = 16) {
	return <div style={{fontFamily, display: 'inline-block', color, fontSize}}>{text}</div>;
}

export const FONTS = {
	FONTS_USAGE
};

export type FontsType = typeof FONTS