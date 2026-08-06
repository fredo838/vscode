/*---------------------------------------------------------------------------------------------
 *  Copyright (c) Microsoft Corporation. All rights reserved.
 *  Licensed under the MIT License. See License.txt in the project root for license information.
 *--------------------------------------------------------------------------------------------*/

declare module 'vscode' {

	export namespace chat {
		/**
		 * Creates a new, unattached local chat session and dispatches one request to it,
		 * targeting the chat participant identified by `participantId` directly — no `@mention`
		 * parsing, and no chat view/widget is ever created or shown. The targeted participant's
		 * {@link ChatExtendedRequestHandler request handler} receives the resulting
		 * {@link ChatRequest} exactly as it would for a normal request, including a valid
		 * {@link ChatRequest.toolInvocationToken toolInvocationToken}.
		 *
		 * `modelId` selects a specific registered `vscode.lm` model (as `<vendor>/<id>`) for the
		 * request, bypassing the default-model lookup a chat request would otherwise need to
		 * resolve — useful when the targeted participant never actually calls
		 * {@link ChatRequest.model} and just needs any valid model to be present.
		 *
		 * The returned promise resolves once the request has been dispatched, not once the
		 * participant's handler returns — a handler that (deliberately) never returns, to keep its
		 * `toolInvocationToken` valid for later reuse, will not hang this call.
		 */
		export function createHeadlessChatSession(participantId: string, modelId?: string): Thenable<void>;
	}
}
