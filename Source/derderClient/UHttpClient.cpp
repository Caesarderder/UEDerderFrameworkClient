// Fill out your copyright notice in the Description page of Project Settings.

#include "UHttpClient.h"
#include "HttpModule.h"
#include "Interfaces/IHttpRequest.h"
#include "Interfaces/IHttpResponse.h"

UHttpClient::UHttpClient()
	: LastResponseLength(0)
{
}

bool UHttpClient::SendPostRequest(const FString& URL, const FString& Headers, const FString& Content, float Timeout)
{
	// 取消之前的请求
	if (CurrentRequest.IsValid() && CurrentRequest->GetStatus() == EHttpRequestStatus::Processing)
	{
		CurrentRequest->CancelRequest();
	}
	
	// 重置状态
	CurrentResponseContent.Empty();
	LastResponseLength = 0;
	
	// 创建HTTP请求
	CurrentRequest = FHttpModule::Get().CreateRequest();
	
	if (!CurrentRequest.IsValid())
	{
		UE_LOG(LogTemp, Error, TEXT("[UHttpClient] 创建HTTP请求失败"));
		return false;
	}
	
	// 设置URL和方法
	CurrentRequest->SetURL(URL);
	CurrentRequest->SetVerb(TEXT("POST"));
	
	// 解析并设置请求头
	TMap<FString, FString> HeaderMap = ParseHeaders(Headers);
	for (const auto& Header : HeaderMap)
	{
		CurrentRequest->SetHeader(Header.Key, Header.Value);
		UE_LOG(LogTemp, Log, TEXT("[UHttpClient] Header: %s = %s"), *Header.Key, *Header.Value);
	}
	
	// 设置请求体
	CurrentRequest->SetContentAsString(Content);
	
	// 设置超时
	CurrentRequest->SetTimeout(Timeout);
	
	// 绑定进度回调
	CurrentRequest->OnRequestProgress().BindUObject(this, &UHttpClient::OnHttpRequestProgress);
	
	// 绑定完成回调
	CurrentRequest->OnProcessRequestComplete().BindUObject(this, &UHttpClient::OnHttpRequestComplete);
	
	// 发送请求
	bool bStarted = CurrentRequest->ProcessRequest();
	
	if (bStarted)
	{
		UE_LOG(LogTemp, Log, TEXT("[UHttpClient] HTTP请求已发送: %s"), *URL);
	}
	else
	{
		UE_LOG(LogTemp, Error, TEXT("[UHttpClient] HTTP请求发送失败"));
	}
	
	return bStarted;
}

void UHttpClient::CancelRequest()
{
	if (CurrentRequest.IsValid())
	{
		CurrentRequest->CancelRequest();
		UE_LOG(LogTemp, Log, TEXT("[UHttpClient] HTTP请求已取消"));
	}
}

FString UHttpClient::GetCurrentResponse() const
{
	return CurrentResponseContent;
}

void UHttpClient::OnHttpRequestProgress(FHttpRequestPtr Request, int32 BytesSent, int32 BytesReceived)
{
	// 获取当前响应
	if (Request.IsValid() && Request->GetResponse().IsValid())
	{
		FHttpResponsePtr Response = Request->GetResponse();
		CurrentResponseContent = Response->GetContentAsString();
		
		// 触发流式回调
		OnRequestProgress.Broadcast(BytesSent, BytesReceived);
		
		// 输出调试信息
		if (CurrentResponseContent.Len() > LastResponseLength)
		{
			int32 NewChunkSize = CurrentResponseContent.Len() - LastResponseLength;
			LastResponseLength = CurrentResponseContent.Len();
			
			UE_LOG(LogTemp, Verbose, TEXT("[UHttpClient] 接收数据: +%d 字节, 总计 %d 字节"), 
				NewChunkSize, LastResponseLength);
		}
	}
}

void UHttpClient::OnHttpRequestComplete(FHttpRequestPtr Request, FHttpResponsePtr Response, bool bSuccess)
{
	FString ResponseContent;
	int32 StatusCode = 0;
	
	if (bSuccess && Response.IsValid())
	{
		StatusCode = Response->GetResponseCode();
		ResponseContent = Response->GetContentAsString();
		CurrentResponseContent = ResponseContent;
		
		UE_LOG(LogTemp, Log, TEXT("[UHttpClient] 请求完成 - 状态码: %d, 响应长度: %d"), 
			StatusCode, ResponseContent.Len());
	}
	else
	{
		UE_LOG(LogTemp, Error, TEXT("[UHttpClient] 请求失败"));
		ResponseContent = TEXT("请求失败");
	}
	
	// 触发完成回调
	OnRequestComplete.Broadcast(bSuccess, ResponseContent, StatusCode);
}

TMap<FString, FString> UHttpClient::ParseHeaders(const FString& HeadersString)
{
	TMap<FString, FString> HeaderMap;
	
	if (HeadersString.IsEmpty())
	{
		return HeaderMap;
	}
	
	// 分割多个请求头（用 | 分隔）
	TArray<FString> HeaderPairs;
	HeadersString.ParseIntoArray(HeaderPairs, TEXT("|"), true);
	
	for (const FString& Pair : HeaderPairs)
	{
		// 分割键值对（用 = 分隔）
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
