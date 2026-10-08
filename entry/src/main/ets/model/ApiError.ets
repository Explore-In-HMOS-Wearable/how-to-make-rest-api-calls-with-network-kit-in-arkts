export enum ApiErrorType {
  NO_NETWORK = 'NO_NETWORK',
  TIMEOUT = 'TIMEOUT',
  HTTP_ERROR = 'HTTP_ERROR',
  PARSE_ERROR = 'PARSE_ERROR',
  UNKNOWN = 'UNKNOWN'
}

export class ApiRequestError extends Error {
  type: ApiErrorType;
  statusCode: number;

  constructor(type: ApiErrorType, message: string, statusCode: number = -1) {
    super(message);
    this.type = type;
    this.statusCode = statusCode;
  }
}
