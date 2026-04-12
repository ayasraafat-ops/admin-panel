import { createOpenAI } from '@ai-sdk/openai';
import { streamText } from 'ai';

// Create an OpenAI instance pointing to the OpenRouter API
const openrouter = createOpenAI({
  baseURL: 'https://openrouter.ai/api/v1',
  apiKey: process.env.OPENROUTER_API_KEY,
});

// Allow streaming responses up to 30 seconds
export const maxDuration = 30;

export async function POST(req: Request) {
  try {
    const { messages } = await req.json();

    if (!messages) {
       return new Response('No messages provided', { status: 400 });
    }

    const result = streamText({
      model: openrouter('qwen/qwen3.6-plus'),
      messages,
    });

    return result.toDataStreamResponse();
  } catch (e) {
    return new Response('Error parsing request body', { status: 400 });
  }
}
