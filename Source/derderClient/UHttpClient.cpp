// Fill out your copyright notice in the Description page of Project Settings.

#include "UHttpClient.h"
#include "HttpModule.h"
#include "Interfaces/IHttpRequest.h"
#include "Interfaces/IHttpResponse.h"
#include "Misc/DateTime.h"

UHttpClient::UHttpClient()
	: LastProcessedLength(0)
	, LastActivityTime(0.0)
	, RequestStartTime(0.0)
{
}

bool UHttpClient::SendPostRequest(const FString& URL, const FString& Headers, const FString& Content, float Timeout)
{
	// Cancel previous request if active
	if (CurrentRequest.IsValid() && CurrentRequest->GetStatus() == EHttpRequestStatus::Processing)
	{
		UE_LOG(LogTemp, Warning, TEXT("[UHttpClient] Canceling active request"));
		CurrentRequest->CancelRequest();
	}
	
	// Reset state
	ResetState();
	
	// Create HTTP request (thread-safe)
	CurrentRequest = FHttpModule::Get().CreateRequest();
	
	if (!CurrentRequest.IsValid())
	{
		UE_LOG(LogTemp, Error, TEXT("[UHttpClient] Failed to create HTTP request"));
		return false;
	}
	
	// Set URL and method
	CurrentRequest->SetURL(URL);
	CurrentRequest->SetVerb(TEXT("POST"));
	
	// Parse and set headers
	TMap<FString, FString> HeaderMap = ParseHeaders(Headers);
	for (const auto& Header : HeaderMap)
	{
		CurrentRequest->SetHeader(Header.Key, Header.Value);
		UE_LOG(LogTemp, Verbose, TEXT("[UHttpClient] Header: %s = %s"), *Header.Key, *Header.Value);
	}
	
	// Set request body
	CurrentRequest->SetContentAsString(Content);
	UE_LOG(LogTemp, Log, TEXT("[UHttpClient] Content size: %d bytes"), Content.Len());
	
	// Set timeout (default 300 seconds for LLM streaming)
	if (Timeout > 0)
	{
		CurrentRequest->SetTimeout(Timeout);
		UE_LOG(LogTemp, Log, TEXT("[UHttpClient] Timeout: %.1f seconds"), Timeout);
	}
	
	// Bind progress callback (async, called from HTTP thread)
	CurrentRequest->OnRequestProgress().BindUObject(this, &UHttpClient::OnHttpRequestProgress);
	
	// Bind completion callback (async, auto-dispatched to GameThread)
	CurrentRequest->OnProcessRequestComplete().BindUObject(this, &UHttpClient::OnHttpRequestComplete);
	
	// Record start time
	RequestStartTime = FPlatformTime::Seconds();
	LastActivityTime = RequestStartTime;
	
	// Send async request
	bool bStarted = CurrentRequest->ProcessRequest();
	
	if (bStarted)
	{
		UE_LOG(LogTemp, Log, TEXT("[UHttpClient] Async request started: %s"), *URL);
	}
	else
	{
		UE_LOG(LogTemp, Error, TEXT("[UHttpClient] Failed to start request"));
		ResetState();
	}
	
	return bStarted;
}

void UHttpClient::CancelRequest()
{
	if (CurrentRequest.IsValid())
	{
		CurrentRequest->CancelRequest();
		UE_LOG(LogTemp, Log, TEXT("[UHttpClient] HTTP request canceled"));
	}
}

FString UHttpClient::GetCurrentResponse() const
{
	return CurrentResponseContent;
}

void UHttpClient::OnHttpRequestProgress(FHttpRequestPtr Request, int32 BytesSent, int32 BytesReceived)
{
	// Update activity time
	LastActivityTime = FPlatformTime::Seconds();
	
	// Get current response (Note: This callback may be called from HTTP thread)
	if (Request.IsValid() && Request->GetResponse().IsValid())
	{
		FHttpResponsePtr Response = Request->GetResponse();
		
		// Get latest response content
		FString NewResponseContent = Response->GetContentAsString();
		int32 CurrentLength = NewResponseContent.Len();
		
		// Only process when new data available
		if (CurrentLength > LastProcessedLength)
		{
			// Extract new chunk (avoid reprocessing)
			FString NewChunk = NewResponseContent.RightChop(LastProcessedLength);
			int32 NewChunkSize = NewChunk.Len();
			
			// Update internal state
			CurrentResponseContent = MoveTemp(NewResponseContent);  // Use Move semantics for performance
			LastProcessedLength = CurrentLength;
			
			// Calculate speed
			double ElapsedTime = LastActivityTime - RequestStartTime;
			double Speed = ElapsedTime > 0 ? (CurrentLength / ElapsedTime) : 0;
			
			UE_LOG(LogTemp, Verbose, TEXT("[UHttpClient] Streaming: +%d bytes | Total: %d bytes | Speed: %.1f B/s"), 
				NewChunkSize, CurrentLength, Speed);
			
			// Trigger streaming callback (pass new chunk)
			// Note: Delegate will be automatically queued to GameThread
			OnRequestProgress.Broadcast(BytesSent, BytesReceived, NewChunk);
		}
	}
}

void UHttpClient::OnHttpRequestComplete(FHttpRequestPtr Request, FHttpResponsePtr Response, bool bSuccess)
{
	// This callback is automatically executed on GameThread
	
	FString ResponseContent;
	int32 StatusCode = 0;
	double TotalTime = FPlatformTime::Seconds() - RequestStartTime;
	
	if (bSuccess && Response.IsValid())
	{
		StatusCode = Response->GetResponseCode();
		ResponseContent = Response->GetContentAsString();
		CurrentResponseContent = ResponseContent;
		
		// Calculate statistics
		int32 ContentLength = ResponseContent.Len();
		double AvgSpeed = TotalTime > 0 ? (ContentLength / TotalTime) : 0;
		
		if (StatusCode >= 200 && StatusCode < 300)
		{
			UE_LOG(LogTemp, Log, TEXT("[UHttpClient] Request completed successfully"));
		UE_LOG(LogTemp, Log, TEXT("  |-- StatusCode: %d"), StatusCode);
		UE_LOG(LogTemp, Log, TEXT("  |-- ContentLength: %d bytes (%.2f KB)"), ContentLength, ContentLength / 1024.0);
		UE_LOG(LogTemp, Log, TEXT("  |-- TotalTime: %.2f sec"), TotalTime);
		UE_LOG(LogTemp, Log, TEXT("  |-- AvgSpeed: %.1f B/s"), AvgSpeed);
		}
		else
		{
		UE_LOG(LogTemp, Warning, TEXT("[UHttpClient] Request completed with abnormal status code: %d"), StatusCode);
		UE_LOG(LogTemp, Warning, TEXT("  |-- Response: %s"), *ResponseContent.Left(200));
		}
	}
	else
	{
		// Detailed error information
		FString FailReason = TEXT("Unknown error");
		
		if (Request.IsValid())
		{
			switch (Request->GetStatus())
			{
			case EHttpRequestStatus::Failed:
				FailReason = TEXT("Request failed");
				break;
			case EHttpRequestStatus::Failed_ConnectionError:
				FailReason = TEXT("Connection error");
				break;
			case EHttpRequestStatus::NotStarted:
				FailReason = TEXT("Request not started");
				break;
			default:
				FailReason = FString::Printf(TEXT("Status: %d"), (int32)Request->GetStatus());
				break;
			}
		}
		
		if (Response.IsValid())
		{
			StatusCode = Response->GetResponseCode();
			ResponseContent = Response->GetContentAsString();
		}
		
		UE_LOG(LogTemp, Error, TEXT("[UHttpClient] Request failed"));
		UE_LOG(LogTemp, Error, TEXT("  |-- Reason: %s"), *FailReason);
		UE_LOG(LogTemp, Error, TEXT("  |-- StatusCode: %d"), StatusCode);
		UE_LOG(LogTemp, Error, TEXT("  |-- TotalTime: %.2f sec"), TotalTime);
		UE_LOG(LogTemp, Error, TEXT("  |-- BytesReceived: %d"), LastProcessedLength);
		
		if (!ResponseContent.IsEmpty())
		{
			UE_LOG(LogTemp, Error, TEXT("  |-- Response: %s"), *ResponseContent.Left(200));
		}
	}
	
	// Trigger completion callback (already on GameThread)
	OnRequestComplete.Broadcast(bSuccess, ResponseContent, StatusCode);
	
	// Cleanup resources
	CurrentRequest.Reset();
}

void UHttpClient::ResetState()
{
	CurrentResponseContent.Empty();
	LastProcessedLength = 0;
	LastActivityTime = 0.0;
	RequestStartTime = 0.0;
}

bool UHttpClient::IsRequestActive() const
{
	return CurrentRequest.IsValid() && CurrentRequest->GetStatus() == EHttpRequestStatus::Processing;
}

TMap<FString, FString> UHttpClient::ParseHeaders(const FString& HeadersString)
{
	TMap<FString, FString> HeaderMap;
	
	if (HeadersString.IsEmpty())
	{
		return HeaderMap;
	}
	
	// Split multiple headers (separated by |)
	TArray<FString> HeaderPairs;
	HeadersString.ParseIntoArray(HeaderPairs, TEXT("|"), true);
	
	for (const FString& Pair : HeaderPairs)
	{
		// Split key-value pairs (separated by =)
		FString Key, Value;
		if (Pair.Split(TEXT("="), &Key, &Value))
		{
			Key.TrimStartAndEndInline();
			Value.TrimStartAndEndInline();
			HeaderMap.Add(Key, Value);
		}
	}
	
	return HeaderMap;
}
