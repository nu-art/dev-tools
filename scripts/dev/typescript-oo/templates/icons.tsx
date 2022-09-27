import * as React from 'react';
import {ElementType, HTMLAttributes} from 'react';
import {_className} from '@nu-art/thunderstorm/frontend';
import {_keys} from '@nu-art/ts-common';


ICONS_DECLARATION;

type IconAttributes = HTMLAttributes<HTMLSpanElement>;

// const genIcon = (Icon: ElementType) =>
// 	(props: IconAttributes) => <div {...props} className={_className('icon--wrapper', props.className)}><Icon/></div>;
const genIcon = (Icon: ElementType) =>
	(props: IconAttributes) => <Icon/>;

const AllIcons = {
	ICONS_USAGE
};

export type IconsType = typeof AllIcons
export type IconKey = keyof IconsType

export const ICONS: IconsType = AllIcons;
export const ICON_KEYS: IconKey[] = _keys(AllIcons);

