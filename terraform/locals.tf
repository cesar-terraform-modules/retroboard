locals {
  iam_email_summary = module.stackgen_a66ffb34_898c_4d02_92cb_5ea38482723e
}

locals {
  dynamodb = module.stackgen_9853203f_e083_4a80_87d3_6575d5d2a3e5
}

locals {
  sd = module.stackgen_5e8e283a_36e8_437c_8c37_35ee89490bbc
}

locals {
  ecs_cluster_name = local.ecs_app.cluster_name
}

locals {
  env = var.environment
}

locals {
  prefix = "retroboard-${local.env}"
}

locals {
  alb = module.stackgen_92de71a0_ae3e_4969_afae_5ac4db9402d4
}

locals {
  iam_api = module.stackgen_cfe1a524_aebc_4f57_8f0a_b50cf509d3a0
}

locals {
  ecs_app = module.stackgen_06bd552c_442f_4a99_86fa_e5787505ead1
}

locals {
  sqs = module.stackgen_ed5d6bb0_86b1_40a4_bcc6_aca8f07f0c18
}

locals {
  sns = module.stackgen_b661ecf9_4189_4639_a2d5_4d2da03fa08c
}

locals {
  ses = module.stackgen_121b0cf0_2050_4bb5_9578_c8dfd5d52f3d
}

