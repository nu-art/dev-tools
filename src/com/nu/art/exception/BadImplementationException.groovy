package com.nu.art.exception

public class BadImplementationException
  extends Exception {

  BadImplementationException() {
  }

  BadImplementationException(String message) {
    super(message)
  }

  BadImplementationException(String message, Throwable cause) {
    super(message, cause)
  }

  BadImplementationException(Throwable cause) {
    super(cause)
  }
}
