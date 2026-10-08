import { ApiRepository } from '../data/ApiRepository';
import { ApiResult } from '../model/ApiResult';
import { PostModel } from '../model/PostModel';
import { ApiRequestError, ApiErrorType } from '../model/ApiError';
import { DemoUiState, CallStatus } from './DemoUiState';

export type StateListener = (state: DemoUiState) => void;

interface ErrorInfo {
  code: number;
  message: string;
}

export class ApiViewModel {
  private repository: ApiRepository = new ApiRepository();
  private listener: StateListener;

  constructor(listener: StateListener) {
    this.listener = listener;
  }

  async runGet(): Promise<void> {
    await this.run<PostModel>(
      'GET /posts/1',
      (): Promise<ApiResult<PostModel>> => this.repository.getPost(1),
      (data: PostModel): string => this.formatPost(data)
    );
  }

  async runPost(): Promise<void> {
    await this.run<PostModel>(
      'POST /posts',
      (): Promise<ApiResult<PostModel>> => this.repository.createPost('Focus session', 'Completed a round.', 1),
      (data: PostModel): string => this.formatPost(data)
    );
  }

  async runPut(): Promise<void> {
    await this.run<PostModel>(
      'PUT /posts/1',
      (): Promise<ApiResult<PostModel>> => this.repository.updatePost(1, 'Updated title', 'Updated body.', 1),
      (data: PostModel): string => this.formatPost(data)
    );
  }

  async runDelete(): Promise<void> {
    await this.run<PostModel | null>(
      'DELETE /posts/1',
      (): Promise<ApiResult<PostModel | null>> => this.repository.deletePost(1),
      (data: PostModel | null): string => data === null ? 'Deleted.' : this.formatPost(data)
    );
  }

  async runForceError(): Promise<void> {
    await this.run<PostModel>(
      'GET /posts/0 (expects 404)',
      (): Promise<ApiResult<PostModel>> => this.repository.triggerNotFound(),
      (data: PostModel): string => this.formatPost(data)
    );
  }

  // --- Shared runner ------------------------------------------------------

  private async run<T>(
    action: string,
    call: () => Promise<ApiResult<T>>,
    format: (data: T) => string
  ): Promise<void> {
    this.emit({ status: CallStatus.LOADING, lastAction: action, statusCode: -1, resultText: '' });
    try {
      const result: ApiResult<T> = await call();
      this.emit({
        status: CallStatus.SUCCESS,
        lastAction: action,
        statusCode: result.statusCode,
        resultText: format(result.data)
      });
    } catch (err) {
      const info: ErrorInfo = this.errorInfo(err);
      this.emit({
        status: CallStatus.ERROR,
        lastAction: action,
        statusCode: info.code,
        resultText: info.message
      });
    }
  }

  private formatPost(model: PostModel): string {
    return `id: ${model.id}\nuserId: ${model.userId}\ntitle: ${model.title}\nbody: ${model.body}`;
  }

  private errorInfo(err: Object): ErrorInfo {
    if (err instanceof ApiRequestError) {
      let message: string;
      switch (err.type) {
        case ApiErrorType.NO_NETWORK:
          message = 'No internet connection.';
          break;
        case ApiErrorType.TIMEOUT:
          message = 'The request timed out.';
          break;
        case ApiErrorType.HTTP_ERROR:
          message = `HTTP error ${err.statusCode}.`;
          break;
        case ApiErrorType.PARSE_ERROR:
          message = 'Could not read the response.';
          break;
        default:
          message = 'Something went wrong.';
          break;
      }
      return { code: err.statusCode, message: message };
    }
    return { code: -1, message: 'Something went wrong.' };
  }

  private emit(state: DemoUiState): void {
    this.listener(state);
  }
}
