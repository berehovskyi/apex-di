public virtual inherited sharing class Di {
    private static final String NOT_FOUND_PROVIDER_ERROR = 'Could not find "{0}" element for export. This provider does not exist in module "{1}".';

    public virtual inherited sharing class Module {
        private final Map<String, Provider> definitions = new Map<String, Provider>();
        private final Set<String> exports = new Set<String>();
        private final String name = String.valueOf(this).substringBefore(':');

        public virtual List<Provider> providers() { return new List<Provider>(); }

        public virtual List<Module> imports() { return new List<Module>(); }

        public virtual Set<String> exports() { return new Set<String>(); }

        public virtual Provider provide(final Type token) {
            return provide(token.getName());
        }

        public virtual Provider provide(final String token) {
            return new Provider(token);
        }

        public virtual String getName() {
            return name;
        }

        public virtual Map<String, Provider> getDefinitions() {
            return definitions;
        }

        protected virtual void register(Set<String> visited) {
            System.debug(LoggingLevel.ERROR, 'visited' + visited);
            if (visited.contains(getName())) {
                return;
            }
            visited.add(getName());

            definitions.clear();
            exports.clear();

            for (Module module : imports()) {
                module.register(visited);
                for (String token : module.exports()) {
                    definitions.put(token, module.getDefinitions().get(token));
                }
            }

            for (Provider provider : providers()) {
                definitions.put(provider.token, provider);
            }

            for (String token : exports()) {
                if (!definitions.containsKey(token)) {
                    throw bindingException(token, getName());
                }
                exports.add(token);
            }
        }
    }

    public virtual inherited sharing class Provider {
        public final String token;
        public String useType { get; private set; }
        public Object useValue { get; private set; }
        public Factory useFactory { get; private set; }
        public Scope scopeType { get; private set; } { scopeType = Scope.SINGLETON; }
        protected Provider(String token) {
            this.token = token;
        }

        public virtual Provider useType(final Type type) {
            return this.useType(type.getName());
        }

        public virtual Provider useType(final String typeName) {
            Validate.notBlank(typeName);
            this.useType = typeName;
            return this;
        }

        public virtual Provider useValue(final Object value) {
            this.useValue = value;
            return this;
        }

        public virtual Provider useFactory(final Factory factory) {
            Validate.isNotNull(factory);
            this.useFactory = factory;
            return this;
        }

        public virtual Provider scope(final Scope scopeType) {
            this.scopeType = scopeType;
            return this;
        }
    }

    public virtual inherited sharing class ModuleRef {
        private final Module module;
        private final Map<String, Object> cache = new Map<String, Object>();

        public ModuleRef(Module module) {
            this.module = module;
            module.register(new Set<String>());
        }

        public virtual Object get(final String token, final Object args) {
            Provider provider = module.getDefinitions().get(token);
            if (provider == null) {
                throw bindingException(token, module.getName());
            }
            if (provider.scopeType == Scope.PROTOTYPE) {
                throw new BindingException('Cannot get prototype-scoped provider for token "' + token + '" via get(), use resolve() instead.');
            }
            if (cache.containsKey(token)) {
                return cache.get(token);
            }
            Object instance = newInstance(provider, args);
            cache.put(token, instance);
            return instance;
        }

        public virtual Object get(final Type token, final Object args) {
            return get(token.getName(), args);
        }

        public virtual Object get(final String token) {
            return get(token, null);
        }

        public virtual Object get(final Type token) {
            return get(token.getName(), null);
        }

        public virtual Object resolve(final String token, final Object args) {
            Provider provider = module.getDefinitions().get(token);
            if (provider == null) {
                throw bindingException(token, module.getName());
            }
            return newInstance(provider, args);
        }

        public virtual Object resolve(final Type token, final Object args) {
            return resolve(token.getName(), args);
        }

        public virtual Object resolve(final String token) {
            return resolve(token, null);
        }

        public virtual Object resolve(final Type token) {
            return resolve(token.getName(), null);
        }

        protected virtual Object newInstance(Provider provider, Object args) {
            if (provider.useValue != null) {
                return provider.useValue;
            } else if (provider.useFactory != null) {
                return provider.useFactory.newInstance(this, args);
            } else if (provider.useType != null) {
                return Type.forName(provider.useType).newInstance();
            }
            throw new BindingException('Invalid provider config for "' + provider.token + '"');
        }
    }

    private static Exception bindingException(String token, String module) {
        return new BindingException(String.format(NOT_FOUND_PROVIDER_ERROR, new List<String>{ token, module }));
    }

    public enum Scope { SINGLETON, PROTOTYPE }

    public interface Factory {
        Object newInstance(ModuleRef ref, Object args);
    }

    public class BindingException extends Exception {}
}
