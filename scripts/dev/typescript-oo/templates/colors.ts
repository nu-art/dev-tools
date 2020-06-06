
COLORS_DECLARATION

function calculateColorWithAlpha(color: string, alpha?: number) {
	return alpha === undefined ? color : color + ((alpha * 256) % 256).toString(16);
}

export const COLORS = {

	COLORS_USAGE
};



