export class NetworkConstants {
  // JSONPlaceholder is a free fake REST API. It accepts GET, POST, PUT and
  // DELETE and echoes the body back, which is ideal for a request-type demo.
  static readonly BASE_HTTPS: string = 'https';
  static readonly URL: string = '://jsonplaceholder.typicode.com';
  static readonly BASE_URL: string = this.BASE_HTTPS + this.URL;
  static readonly POSTS_PATH: string = '/posts';

  // Timeouts
  static readonly CONNECT_TIMEOUT_MS: number = 8000;
  static readonly READ_TIMEOUT_MS: number = 8000;

  // Retry policy
  static readonly MAX_RETRY: number = 2;
  static readonly RETRY_DELAY_MS: number = 1500;
}
