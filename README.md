# skarb_plugin

A new Flutter plugin project.

## Getting Started

To use this plugin in Android, add this to your build.gradle file under allprojects/repositories:

```gradle
maven {
    url "https://gitlab.com/api/v4/projects/57611358/packages/maven"
    name "gitlab-maven"
    credentials(HttpHeaderCredentials) {
        name = "Private-Token"
        value = "glpat-Pq34s7MyqUjmC2ZbbVZy"
    }
    authentication {
        header(HttpHeaderAuthentication)
    }
}
```

The private token is for v.starikov account on gitlab.com. It is used to access the android plugin package on gitlab.com.

