/*---------------------------------------------------------------------------------------------
 *  Copyright (c) Microsoft Corporation. All rights reserved.
 *  Licensed under the MIT License. See License.txt in the project root for license information.
 *--------------------------------------------------------------------------------------------*/

declare module 'vscode' {

	/**
	 * A single question within a {@link ChatQuestionCarouselRequestEvent}, mirroring what VS
	 * Code's own chat widget would render for it (e.g. the Integrated-Browser "Share Browser Tab"
	 * prompt). Options are present for single/multi-select questions; free text questions have
	 * none.
	 */
	export interface ChatQuestionCarouselQuestion {
		readonly id: string;
		readonly title: string;
		readonly message?: string;
		readonly options?: readonly { readonly id: string; readonly label: string; readonly value: string }[];
		readonly defaultValue?: string | string[];
		readonly allowFreeformInput?: boolean;
		readonly required?: boolean;
	}

	/**
	 * Fired via {@link chat.onDidRequestQuestionCarousel} when VS Code appends an unanswered
	 * question carousel to a chat request's response — the same mechanism that shows prompts like
	 * "Share Browser Tab" inline in the chat view. An extension that owns `sessionResource` (e.g.
	 * one of its own chat participant's sessions) can render its own UI for this instead of
	 * requiring VS Code's chat view to be visible, then answer it with
	 * {@link chat.answerQuestionCarousel}.
	 */
	export interface ChatQuestionCarouselRequestEvent {
		readonly sessionResource: Uri;
		readonly requestId: string;
		readonly resolveId: string;
		readonly questions: readonly ChatQuestionCarouselQuestion[];
		readonly message?: string;
		readonly allowSkip: boolean;
	}

	export namespace chat {
		/**
		 * An event that fires whenever a new, unanswered question carousel appears in any chat
		 * session — filter by {@link ChatQuestionCarouselRequestEvent.sessionResource} to find
		 * ones belonging to your own extension's sessions.
		 */
		export const onDidRequestQuestionCarousel: Event<ChatQuestionCarouselRequestEvent>;

		/**
		 * Answers a question carousel previously surfaced via {@link onDidRequestQuestionCarousel},
		 * identified by the same `requestId`/`resolveId` from that event. `answers` maps each
		 * answered question's {@link ChatQuestionCarouselQuestion.id id} to the selected option's
		 * `value` (or free text, if the question allows it); omit or leave a question's id out to
		 * skip it.
		 */
		export function answerQuestionCarousel(requestId: string, resolveId: string, answers: { [questionId: string]: string } | undefined): void;
	}
}
