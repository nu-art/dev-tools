import * as React from 'react';
import {HTMLAttributes} from 'react';

export type IconStyle = {
	color: string;
	width: number;
	height: number;
}

type IconAttributes = HTMLAttributes<HTMLSpanElement>;
type Props = IconAttributes & {
	icon: string
}

class RenderIcon
	extends React.Component<Props> {
	render() {
		return <div {...this.props} className={`icon--default ${this.props.className}`}
								style={{WebkitMaskImage: `url(${this.props.icon})`, maskImage: `url(${this.props.icon})`}}/>;
	}
}

export type IconData = {
	ratio: number,
	value: string
}

export const iconsRenderer = (key: IconData, props?: IconAttributes) => {
	return <RenderIcon {...props} icon={key.value}/>;
};

ICONS_DECLARATION;

export const ICONS = {
	ICONS_USAGE
};

export type IconsType = typeof ICONS