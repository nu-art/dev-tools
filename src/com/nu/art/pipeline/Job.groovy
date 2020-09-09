public class Job
  implements Serializable {

  String name
  def params = []

  public <T> Job addParam(JobParam<T> type, GString key, T value) {
    return this.addParam(type, key.toString(), value)
  }

  public <T> Job addParam(JobParam<T> type, String key, T value) {
    params += [$class: type.key, name: key, value: value.toString()]
    return this
  }

  run() {
    script.build job: name, parameters: params
  }
}
