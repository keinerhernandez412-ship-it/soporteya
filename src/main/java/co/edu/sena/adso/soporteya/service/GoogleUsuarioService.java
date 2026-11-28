package co.edu.sena.adso.soporteya.service;

import java.util.Set;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.security.core.GrantedAuthority;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.oauth2.client.oidc.userinfo.OidcUserRequest;
import org.springframework.security.oauth2.client.oidc.userinfo.OidcUserService;
import org.springframework.security.oauth2.core.OAuth2AuthenticationException;
import org.springframework.security.oauth2.core.OAuth2Error;
import org.springframework.security.oauth2.core.oidc.user.DefaultOidcUser;
import org.springframework.security.oauth2.core.oidc.user.OidcUser;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import co.edu.sena.adso.soporteya.model.Rol;
import co.edu.sena.adso.soporteya.model.Usuario;
import co.edu.sena.adso.soporteya.repository.AreaRepository;
import co.edu.sena.adso.soporteya.repository.UsuarioRepository;

// Opcional · Google confirma quién es la persona; SoporteYa decide qué rol tiene.
// La primera vez que alguien entra con Google se crea como SOLICITANTE (sin contraseña local).
@Service
public class GoogleUsuarioService extends OidcUserService {

    private final UsuarioRepository usuarios;
    private final AreaRepository areas;
    private final String dominio;

    public GoogleUsuarioService(UsuarioRepository usuarios, AreaRepository areas,
                                @Value("${soporteya.dominio-correo}") String dominio) {
        this.usuarios = usuarios;
        this.areas = areas;
        this.dominio = dominio;
    }

    @Override
    @Transactional
    public OidcUser loadUser(OidcUserRequest solicitud) throws OAuth2AuthenticationException {
        OidcUser google = super.loadUser(solicitud);
        String email = google.getEmail().toLowerCase();
        if (!email.endsWith("@" + dominio)) {
            throw new OAuth2AuthenticationException(new OAuth2Error("dominio_no_permitido"),
                    "Solo cuentas @" + dominio);
        }
        Usuario usuario = usuarios.findByEmail(email).orElseGet(() -> usuarios.save(
                new Usuario(google.getFullName(), email, Rol.SOLICITANTE, areas.findAllByOrderByNombreAsc().get(0))));
        if (!usuario.isActivo()) {
            throw new OAuth2AuthenticationException(new OAuth2Error("usuario_inactivo"), "La cuenta está desactivada");
        }
        Set<GrantedAuthority> roles = Set.of(new SimpleGrantedAuthority("ROLE_" + usuario.getRol().name()));
        // "email" como nombre: así Principal.getName() devuelve el correo, igual que con el formulario
        return new DefaultOidcUser(roles, google.getIdToken(), google.getUserInfo(), "email");
    }
}