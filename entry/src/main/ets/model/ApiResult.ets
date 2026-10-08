export interface ApiResult<T> {
  statusCode: number;
  data: T;
}
