package com.nu.art.utils

class Colors {
	static String randomColor() {
		return "#${UUID.randomUUID().toString().replace("-", "").substring(0, 6)}"
	}

	public static String LightGray = "#DDDDDD"
	public static String Gray = "#AAAAAA"
	public static String DarkGray = "#666666"
	public static String Blue = "#0774E0"
	public static String LightBlue = "#C2E5FF"
	public static String Red = "#C70700"
	public static String Yellow = "#F5C242"
	public static String Green = "#18A100"
}
