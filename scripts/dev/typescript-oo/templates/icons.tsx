import * as React from 'react';
import {ElementType, HTMLAttributes} from 'react';
import {_className} from '@nu-art/thunderstorm/frontend';
import {_keys} from '@nu-art/ts-common';


ICONS_DECLARATION;

const genIcon = (Icon: ElementType) =>
	(props: HTMLAttributes<HTMLSpanElement>) => <div {...props} className={_className('ll_v_c match_height flex__justify-center ts-icon', props.className)}>
		<Icon/>
	</div>;

const genIconV4 = (icon: ElementType) =>
	(props: HTMLAttributes<HTMLDivElement>) => {
		const className = _className('ts-icon__v4', props.className);
		return <div {...props} className={className} style={{WebkitMaskImage: `url(${icon})`, maskImage: `url(${icon})`}}/>;
	};

const AllIcons = {
	ICONS_USAGE
};

const AllIconsV4 = {

	ICONS_V4_USAGE
};

export type IconsType = typeof AllIcons
export type IconKey = keyof IconsType

export const ICONS: IconsType = AllIcons;
export const ICONSV4: typeof AllIconsV4 = AllIconsV4;
export const ICON_KEYS: IconKey[] = _keys(AllIcons);

