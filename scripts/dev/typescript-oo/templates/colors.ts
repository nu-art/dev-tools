
COLORS_DECLARATION

function calculateColorWithAlpha(color: string, alpha?: number) {
	return color + (255 - Math.round((alpha * 256) % 256)).toString(16);
}

export const COLORS = {

	COLORS_USAGE
};

export type ColorsType = typeof COLORS