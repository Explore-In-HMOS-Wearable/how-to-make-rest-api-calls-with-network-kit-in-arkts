import { http } from '@kit.NetworkKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { NetworkConstants } from '../common/constants/NetworkConstants';
import { NetworkUtil } from '../utils/NetworkUtil';
import { PostDto, PostInputDto } from '../model/PostResponse';
import { PostModel } from '../model/PostModel';
import { ApiResult } from '../model/ApiResult';
import { ApiRequestError, ApiErrorType } from '../model/ApiError';

const DOMAIN: number = 0x0000;
const TAG: string = 'NetworkKitDemo';

// Status codes worth retrying: request timeout and transient server errors.
const RETRYABLE_STATUS: number[] = [408, 500, 502, 503, 504];

// Network Kit maps a connection/read timeout to this error code (libcurl code 28).
const TIMEOUT_ERROR_CODE: number = 2300028;

export class ApiRepository {
  // GET
  getPost(id: number): Promise<ApiResult<PostModel>> {
    const url: string = `${NetworkConstants.BASE_URL}${NetworkConstants.POSTS_PATH}/${id}`;
    return this.send<PostModel>(
      http.RequestMethod.GET, url, undefined,
      (raw: string): PostModel => this.toModel(raw),
      NetworkConstants.MAX_RETRY
    );
  }

  // POST
  createPost(title: string, body: string, userId: number): Promise<ApiResult<PostModel>> {
    const url: string = `${NetworkConstants.BASE_URL}${NetworkConstants.POSTS_PATH}`;
    const input: PostInputDto = { title: title, body: body, userId: userId };
    const payload: string = JSON.stringify(input);
    return this.send<PostModel>(
      http.RequestMethod.POST, url, payload,
      (raw: string): PostModel => this.toModel(raw),
      NetworkConstants.MAX_RETRY
    );
  }

  // PUT
  updatePost(id: number, title: string, body: string, userId: number): Promise<ApiResult<PostModel>> {
    const url: string = `${NetworkConstants.BASE_URL}${NetworkConstants.POSTS_PATH}/${id}`;
    const full: PostDto = {
      id: id,
      title: title,
      body: body,
      userId: userId
    };
    const payload: string = JSON.stringify(full);
    return this.send<PostModel>(
      http.RequestMethod.PUT, url, payload,
      (raw: string): PostModel => this.toModel(raw),
      NetworkConstants.MAX_RETRY
    );
  }

  // DELETE
  deletePost(id: number): Promise<ApiResult<PostModel | null>> {
    const url: string = `${NetworkConstants.BASE_URL}${NetworkConstants.POSTS_PATH}/${id}`;
    return this.send<PostModel | null>(
      http.RequestMethod.DELETE, url, undefined,
      (raw: string): PostModel | null => null,
      NetworkConstants.MAX_RETRY
    );
  }

  // GET /posts/0 returns 404, so this shows the error and status-code path.
  triggerNotFound(): Promise<ApiResult<PostModel>> {
    const url: string = `${NetworkConstants.BASE_URL}${NetworkConstants.POSTS_PATH}/0`;
    return this.send<PostModel>(
      http.RequestMethod.GET, url, undefined,
      (raw: string): PostModel => this.toModel(raw),
      0
    );
  }

  private async send<T>(
    method: http.RequestMethod,
    url: string,
    body: string | undefined,
    parse: (raw: string) => T,
    retriesLeft: number
  ): Promise<ApiResult<T>> {
    // Fail fast and clearly if there is no network, before touching HTTP.
    if (!NetworkUtil.isNetworkAvailable()) {
      throw new ApiRequestError(ApiErrorType.NO_NETWORK, 'No usable network connection.');
    }
    try {
      return await this.sendOnce<T>(method, url, body, parse);
    } catch (err) {
      const canRetry: boolean = retriesLeft > 0 && this.isRetryable(err);
      if (!canRetry) {
        throw err as Error;
      }
      hilog.warn(DOMAIN, TAG, `request failed, retrying, attempts left: ${retriesLeft}`);
      await this.delay(NetworkConstants.RETRY_DELAY_MS);
      return this.send<T>(method, url, body, parse, retriesLeft - 1);
    }
  }

  private isRetryable(err: Object): boolean {
    if (err instanceof ApiRequestError) {
      if (err.type === ApiErrorType.TIMEOUT) {
        return true;
      }
      if (err.type === ApiErrorType.HTTP_ERROR) {
        return RETRYABLE_STATUS.includes(err.statusCode);
      }
    }
    return false;
  }

  private async sendOnce<T>(
    method: http.RequestMethod,
    url: string,
    body: string | undefined,
    parse: (raw: string) => T
  ): Promise<ApiResult<T>> {
    // Each request needs its own HttpRequest. It cannot be reused after destroy.
    const httpRequest: http.HttpRequest = http.createHttp();

    httpRequest.on('headersReceive', (header: Object) => {
      hilog.info(DOMAIN, TAG, `headers received: ${JSON.stringify(header)}`);
    });

    const options: http.HttpRequestOptions = {
      method: method,
      header: this.buildHeader(body !== undefined),
      extraData: body,
      expectDataType: http.HttpDataType.STRING,
      connectTimeout: NetworkConstants.CONNECT_TIMEOUT_MS,
      readTimeout: NetworkConstants.READ_TIMEOUT_MS
    };

    try {
      const response: http.HttpResponse = await httpRequest.request(url, options);
      this.validateStatus(response.responseCode);
      const data: T = parse(response.result as string);
      return { statusCode: response.responseCode, data: data };
    } catch (err) {
      throw this.toApiError(err);
    } finally {
      // Always clean up, success or failure.
      httpRequest.off('headersReceive');
      httpRequest.destroy();
    }
  }

  private buildHeader(hasBody: boolean): Record<string, string> {
    if (hasBody) {
      // A request with a body must declare its content type.
      return {
        'Accept': 'application/json',
        'Content-Type': 'application/json; charset=UTF-8'
        // 'Authorization': 'Bearer <your-token>'  // if your API needs it
      };
    }
    return {
      'Accept': 'application/json'
    };
  }

  private validateStatus(code: number): void {
    if (code >= 200 && code <= 299) {
      return;
    }
    throw new ApiRequestError(ApiErrorType.HTTP_ERROR, `Server returned status ${code}.`, code);
  }

  private toModel(raw: string): PostModel {
    const dto: PostDto = this.parseDto(raw);
    const model: PostModel = {
      id: dto.id,
      userId: dto.userId,
      title: dto.title,
      body: dto.body
    };
    return model;
  }

  private parseDto(raw: string): PostDto {
    try {
      return JSON.parse(raw) as PostDto;
    } catch (err) {
      throw new ApiRequestError(ApiErrorType.PARSE_ERROR, 'Response was not valid JSON.');
    }
  }

  private toApiError(err: Object): ApiRequestError {
    if (err instanceof ApiRequestError) {
      return err;
    }
    const be = err as BusinessError;
    const message: string = be && be.message ? be.message : 'Unknown network error.';
    if (be && be.code === TIMEOUT_ERROR_CODE) {
      return new ApiRequestError(ApiErrorType.TIMEOUT, message);
    }
    return new ApiRequestError(ApiErrorType.UNKNOWN, message);
  }

  private delay(ms: number): Promise<void> {
    return new Promise<void>((resolve: () => void) => {
      setTimeout(() => {
        resolve();
      }, ms);
    });
  }
}
