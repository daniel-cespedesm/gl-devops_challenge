#!groovy

import jenkins.model.*
import hudson.security.*
import jenkins.security.s2m.AdminWhitelistRule

def instance = Jenkins.get()

def hudsonRealm = new HudsonPrivateSecurityRealm(false)
hudsonRealm.createAccount("gorilla", "GorillaLogic")
instance.setSecurityRealm(hudsonRealm)

def strategy = new FullControlOnceLoggedInAuthorizationStrategy()
instance.setAuthorizationStrategy(strategy)
instance.save()

def user = instance.getUser("gorilla")
user.setFullName("Gorilla Administrator")
user.setDescription("Gorilla Logic challenge user admin")
user.save()
instance.save()

Jenkins.instance.getInjector().getInstance(AdminWhitelistRule.class).setMasterKillSwitch(false)
