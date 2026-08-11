/*---------------------------------------------------------------------------------------------
 *  Copyright (c) Microsoft Corporation. All rights reserved.
 *  Licensed under the MIT License. See License.txt in the project root for license information.
 *--------------------------------------------------------------------------------------------*/

declare module 'vscode' {

	export namespace chat {
		/**
		 * Starts a new, unattached local chat session — no chat view/widget is ever created or
		 * shown. Mirrors what VS Code's own chat view/editor does internally to create a session,
		 * exposed so an extension can dispatch a request to it directly with
		 * {@link sendRequest}, e.g. to obtain a valid {@link ChatRequest.toolInvocationToken}
		 * without ever showing the native Chat UI.
		 *
		 * The returned handle is opaque and only meaningful as an argument to {@link sendRequest}.
		 */
		export function startSession(): Thenable<number>;

		/**
		 * Dispatches one request to a session previously returned by {@link startSession},
		 * targeting the chat participant identified by `options.agentId` directly — no `@mention`
		 * parsing. The targeted participant's {@link ChatExtendedRequestHandler request handler}
		 * receives the resulting {@link ChatRequest} exactly as it would for a normal request,
		 * including a valid {@link ChatRequest.toolInvocationToken toolInvocationToken}.
		 *
		 * `options.userSelectedModelId` selects a specific registered `vscode.lm` model (as
		 * `<vendor>/<id>`) for the request, bypassing the default-model lookup a chat request
		 * would otherwise need to resolve — useful when the targeted participant never actually
		 * calls {@link ChatRequest.model} and just needs any valid model to be present.
		 *
		 * The returned promise resolves once the request has been dispatched, not once the
		 * participant's handler returns — a handler that (deliberately) never returns, to keep its
		 * `toolInvocationToken` valid for later reuse, will not hang this call.
		 */
		export function sendRequest(session: number, message: string, options?: { agentId?: string; userSelectedModelId?: string }): Thenable<void>;
	}
}
