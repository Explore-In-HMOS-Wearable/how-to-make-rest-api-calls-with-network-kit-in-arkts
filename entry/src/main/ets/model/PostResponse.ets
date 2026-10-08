export interface PostDto {
  userId: number;
  id: number;
  title: string;
  body: string;
}

export interface PostInputDto {
  title: string;
  body: string;
  userId: number;
}
