// empty line
COLORS_DECLARATION;

function calculateColorWithAlpha(color: string, alpha: number = 1) {
	return color + (255 - Math.round(((1 - alpha) * 256) % 256)).toString(16);
}

export const COLORS = {

	COLORS_USAGE
};

export type ColorsType = typeof COLORS