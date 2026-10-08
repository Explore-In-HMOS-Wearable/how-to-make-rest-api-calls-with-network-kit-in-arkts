export enum CallStatus {
  IDLE = 'IDLE',
  LOADING = 'LOADING',
  SUCCESS = 'SUCCESS',
  ERROR = 'ERROR'
}

export interface DemoUiState {
  status: CallStatus;
  lastAction: string;   // e.g. "GET /posts/1"
  statusCode: number;   // -1 when there is no code yet
  resultText: string;   // parsed body, or an error message
}
