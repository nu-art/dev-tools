package com.nu.art.pipeline.interfaces

interface Shell<T extends Shell> {
  T sh(String command)
}