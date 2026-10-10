from aws_cdk import (
    Stack,
    Duration,
    aws_lambda as _lambda,
    aws_apigateway as apigateway,
)
from constructs import Construct


class MeinCdkProjektStack(Stack):

    def __init__(self, scope: Construct, construct_id: str, **kwargs) -> None:
        super().__init__(scope, construct_id, **kwargs)


        lambdalayer = _lambda.LayerVersion(
            self,
            "MeinPython311Layer",
            code=_lambda.Code.from_asset("lambda_layer"),
            compatible_runtimes=[_lambda.Runtime.PYTHON_3_11],
            description="Mein Python 3.11 Library Layer",
        )

        workerlambda = _lambda.Function(
            self,
            "GeneratorLambda",
            function_name="generator",
            runtime=_lambda.Runtime.PYTHON_3_11,
            handler="lambda.handler",
            code=_lambda.Code.from_asset("lambda_function"),
            layers=[lambdalayer],

           
            timeout=Duration.seconds(60),

           
            memory_size=512,
        )


        meine_api = apigateway.RestApi(
            self,
            "WorkerApiGateway",
            rest_api_name="worker",
            deploy_options=apigateway.StageOptions(
                throttling_rate_limit=10,
                throttling_burst_limit=20,
            ),
            default_cors_preflight_options=apigateway.CorsOptions(
                allow_origins=[
                    "https://placeholder.de",
                ],
                allow_methods=["POST", "OPTIONS"],
                allow_headers=["Content-Type", "Authorization"],
            ),
        )


        lambdaintegration = apigateway.LambdaIntegration(
            workerlambda,
            proxy=False,
            request_parameters={
                "integration.request.header.X-Amz-Invocation-Type": "'Event'"
            },
            integration_responses=[
                apigateway.IntegrationResponse(
                    status_code="202",
                    response_templates={
                        "application/json": '{"accepted": true}'
                    },
                    response_parameters={
                        "method.response.header.Access-Control-Allow-Origin":
                            "'https://placeholder.de'",
                        "method.response.header.Content-Type":
                            "'application/json'",
                    },
                )
            ],
        )

        # API-Pfad: /api/worker
        api_ordner = meine_api.root.add_resource("api")
        worker_ressource = api_ordner.add_resource("worker")

        # POST-Methode
        worker_ressource.add_method(
            "POST",
            lambdaintegration,
            method_responses=[
                apigateway.MethodResponse(
                    status_code="202",
                    response_parameters={
                        "method.response.header.Access-Control-Allow-Origin": True,
                        "method.response.header.Content-Type": True,
                    },
                )
            ],
        )